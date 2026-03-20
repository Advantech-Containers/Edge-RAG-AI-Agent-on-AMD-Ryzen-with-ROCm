import os
from pathlib import Path

from langchain_community.document_loaders import PyPDFLoader
from langchain.text_splitter import RecursiveCharacterTextSplitter

from langchain_community.embeddings import HuggingFaceEmbeddings
from langchain_community.vectorstores import FAISS

from langchain.chains import RetrievalQA


# Global embedding cache
_embeddings = None


def get_embeddings():

    global _embeddings

    if _embeddings is None:

        model_name = os.getenv(
            "EMBEDDING_MODEL",
            "sentence-transformers/sentence-t5-base"
        )

        print(f"[INFO] Loading embedding model: {model_name}")

        _embeddings = HuggingFaceEmbeddings(
            model_name=model_name,
            model_kwargs={
                "device": "cpu"
            }
        )

    return _embeddings


# Load all PDFs in the given directory
def load_all_pdfs(pdf_dir: str):

    all_docs = []

    for pdf_path in Path(pdf_dir).glob("*.pdf"):

        loader = PyPDFLoader(str(pdf_path))
        pages = loader.load()

        for page in pages:
            page.metadata["source"] = pdf_path.name

        all_docs.extend(pages)

    print(f"[INFO] Loaded {len(all_docs)} pages from PDFs")

    return all_docs


# Load PDF
def load_pdf(path):

    loader = PyPDFLoader(path)

    pages = loader.load()

    return pages


# Split into chunks
def split_docs(docs):

    splitter = RecursiveCharacterTextSplitter(
        chunk_size=1000,
        chunk_overlap=200
    )

    chunks = splitter.split_documents(docs)

    print(f"[INFO] Split into {len(chunks)} chunks")

    return chunks


# Create vector store using FAISS
def create_vectorstore(chunks):

    embeddings = get_embeddings()

    print("[INFO] Building FAISS vector store...")

    vectorstore = FAISS.from_documents(
        chunks,
        embedding=embeddings
    )

    print("[INFO] FAISS index created")

    return vectorstore


# Create QA chain
def create_qa_chain(llm, retriever):

    return RetrievalQA.from_chain_type(
        llm=llm,
        retriever=retriever,
        return_source_documents=True
    )
