import multer from "multer";
import pdfParse from "pdf-parse"; // Ensure version 2.0.0+
import mammoth from "mammoth";
import User from "../models/User.js";

const upload = multer({ storage: multer.memoryStorage() });

class CVController {
  static uploadCV = upload.single("cv");

  static async processCV(req, res) {
    try {
      const file = req.file;
      if (!file) return res.status(400).send("No file uploaded");

      let text;

      if (file.mimetype === "application/pdf") {
        const pdfDoc = await pdfjsLib.getDocument(file.buffer).promise;
        const page = await pdfDoc.getPage(1);
        const content = await page.getTextContent();
        text = content.items.map((item) => item.str).join(" ");
      } else if (
        file.mimetype ===
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      ) {
        const data = await mammoth.extractRawText({ buffer: file.buffer });
        text = data.value;
      } else {
        return res.status(400).send("Unsupported file type");
      }

      // Improved regex patterns with case-insensitive matching
      const cvData = {
        personal: text.match(/Name:\s*(.+)/i)?.[1]?.trim() || "",
        education: text.match(/Education:\s*(.+)/i)?.[1]?.trim() || "",
        experience: text.match(/Experience:\s*(.+)/i)?.[1]?.trim() || "",
        skills: text.match(/Skills:\s*(.+)/i)?.[1]?.trim() || "",
      };

      await User.findByIdAndUpdate(req.user.id, { cv: cvData });
      res.redirect("/dashboard");
    } catch (error) {
      console.error("CV Processing Error:", error);
      res.status(500).send("Error processing CV. Please try again.");
    }
  }
}

export default CVController;
