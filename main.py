import re
import sys
from pathlib import Path
from markitdown import MarkItDown


def extract_fase_number(filename: str) -> int:
    match = re.search(r"Fase\s*(\d+)", filename, re.IGNORECASE)
    return int(match.group(1)) if match else sys.maxsize


def main():
    script_dir = Path(__file__).parent
    pdf_dir = script_dir / "pdfs"

    if not pdf_dir.is_dir():
        print(f"Error: No se encuentra el directorio '{pdf_dir}'.")
        return

    pdf_files = sorted(
        list(pdf_dir.rglob("*.pdf")),
        key=lambda f: extract_fase_number(f.name),
    )

    if not pdf_files:
        print("No se encontraron archivos PDF en el directorio 'pdfs/'.")
        return

    converter = MarkItDown()
    output_dir = script_dir / "markdown"
    output_dir.mkdir(exist_ok=True)

    all_content = []
    total = len(pdf_files)

    for i, pdf_path in enumerate(pdf_files, 1):
        stem = pdf_path.stem
        md_path = output_dir / f"{stem}.md"
        print(f"[{i}/{total}] Procesando: {pdf_path.name}")

        result = converter.convert(str(pdf_path))
        text = result.text_content

        md_path.write_text(text, encoding="utf-8")

        header = f"# {stem}\n\n"
        all_content.append(header + text)

    merged = output_dir / "FASE_COMPLETA.md"
    merged.write_text("\n\n---\n\n".join(all_content), encoding="utf-8")

    print(f"\n[OK] {total} PDFs convertidos a Markdown en: {output_dir}")
    print(f"[OK] Archivo combinado: {merged.name}")


if __name__ == "__main__":
    main()
