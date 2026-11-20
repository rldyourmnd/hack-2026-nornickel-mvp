from __future__ import annotations

import logging
import os
from collections.abc import Callable, Iterable
from functools import lru_cache
from typing import cast

logger = logging.getLogger(__name__)

# BAAI/bge-reranker-v2-m3 is a multilingual XLM-R cross-encoder.
_DEFAULT_MODEL_ID = "BAAI/bge-reranker-v2-m3"

type _Predictor = Callable[[list[tuple[str, str]]], Iterable[float]]


def _sentence_transformers_predictor(model_id: str, backend: str) -> _Predictor:
    from sentence_transformers import CrossEncoder

    return cast(_Predictor, CrossEncoder(model_id, backend=backend, device="cpu").predict)


@lru_cache(maxsize=1)
def _load_predictor() -> _Predictor:
    model_id = os.getenv("RERANKER_MODEL_ID", _DEFAULT_MODEL_ID)
    backend = os.getenv("RERANKER_BACKEND", "onnx")
    logger.info("Loading reranker %s (backend=%s)", model_id, backend)
    try:
        if backend == "onnx":
            from fastembed.rerank.cross_encoder import TextCrossEncoder

            model = TextCrossEncoder(model_name=model_id, providers=["CPUExecutionProvider"])
            return cast(_Predictor, model.rerank_pairs)
        return _sentence_transformers_predictor(model_id, backend)
    except Exception:
        if backend == "torch":
            raise
        logger.warning("Reranker backend %s unavailable; falling back to torch", backend)
        return _sentence_transformers_predictor(model_id, "torch")


class CrossEncoderReranker:
    """Query-document relevance reranking on CPU.

    Applied to the hybrid-retrieval candidate pool (top-30) to pick the final
    top-k; the single most reliable component-level precision boost for RAG.
    """

    max_chars = 1600  # ~512 tokens; cross-encoder input cap

    def rerank(
        self,
        query: str,
        candidates: list[tuple[str, str]],
        *,
        top_k: int,
    ) -> list[str]:
        """(unit_id, text) candidates -> unit_ids of the top_k most relevant."""
        if not candidates:
            return []
        if len(candidates) <= top_k:
            ordered = candidates
        else:
            pairs = [(query, text[: self.max_chars]) for _, text in candidates]
            scores = _load_predictor()(pairs)
            ranked = sorted(
                zip(candidates, scores, strict=True), key=lambda item: -float(item[1])
            )
            ordered = [candidate for candidate, _ in ranked]
        return [unit_id for unit_id, _ in ordered[:top_k]]
