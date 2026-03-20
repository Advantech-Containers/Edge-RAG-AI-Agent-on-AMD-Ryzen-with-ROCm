import os
from langchain_community.llms import Ollama
from langchain.callbacks.base import BaseCallbackHandler


def to_int(value):
    try:
        return int(value)
    except (TypeError, ValueError):
        return None


def to_float(value):
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


class MyLoggingHandler(BaseCallbackHandler):

    def on_llm_start(self, *args, **kwargs):
        print("\n=== LLM Request Start ===")

    def on_llm_end(self, *args, **kwargs):
        print("\n=== LLM Request End ===")


def get_llm(callback_handler=None):

    system_prompt = """
You are a helpful assistant with access to a knowledge base (document) and general world knowledge.

- If the question is general (greeting, science, history, math, biology, chemistry etc.), answer using your own knowledge.
- If the question is specific to the uploaded document (EdgeSync, containers, APIs etc.), use the document context.
- If the document is not relevant, answer using your own knowledge.
- Never use the document for greetings like Hi, Hello.

Example:
User: Hi
Assistant: Hi, how can I assist you?
"""

    callbacks = [MyLoggingHandler()]

    if callback_handler:
        callbacks.insert(0, callback_handler)

    llm = Ollama(
        base_url=os.getenv("OLLAMA_API_BASE"),
        model=os.getenv("MODEL_NAME"),

        temperature=to_float(os.getenv("TEMPERATURE", 0.7)),
        num_ctx=to_int(os.getenv("NUM_CTX")),
        num_gpu=to_int(os.getenv("NUM_GPU")),
        num_thread=to_int(os.getenv("NUM_THREAD")),

        keep_alive=os.getenv("KEEP_ALIVE"),

        repeat_penalty=to_float(os.getenv("REPEAT_PENALTY")),
        top_p=to_float(os.getenv("TOP_P")),
        top_k=to_int(os.getenv("TOP_K")),

        template=os.getenv("TEMPLATE"),

        system=os.getenv("SYSTEM", system_prompt),

        callbacks=callbacks,

        verbose=False
    )

    return llm
