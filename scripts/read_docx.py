import zipfile
import xml.etree.ElementTree as ET
import os

def get_docx_text(path):
    if not os.path.exists(path):
        return f"Error: File '{path}' does not exist."
    try:
        with zipfile.ZipFile(path) as doc:
            xml_content = doc.read('word/document.xml')
            tree = ET.XML(xml_content)
            
            # Namespace for Word Processing ML
            w_namespace = '{http://schemas.openxmlformats.org/wordprocessingml/2006/main}'
            p_tag = f'{w_namespace}p'
            t_tag = f'{w_namespace}t'
            
            paragraphs = []
            for paragraph in tree.iter(p_tag):
                texts = [node.text for node in paragraph.iter(t_tag) if node.text]
                if texts:
                    paragraphs.append("".join(texts))
            return "\n".join(paragraphs)
    except Exception as e:
        return f"Error parsing docx: {e}"

if __name__ == "__main__":
    docx_path = "ProjectIntroduction.docx"
    print(get_docx_text(docx_path))
