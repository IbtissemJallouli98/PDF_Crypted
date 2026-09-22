package com.tb2si.pdf;

import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.junit.jupiter.api.Test;

import java.io.ByteArrayOutputStream;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

class PdfEncryptionServiceTest {
    @Test
    void encryptedPdfRequiresTheCorrectPasswordAndAllowsPrinting() throws Exception {
        byte[] source = simplePdf();
        PdfEncryptionService service = new PdfEncryptionService(4_500_000);
        byte[] encrypted = service.encrypt(source, "user-password", "owner-password");

        assertThrows(Exception.class, () -> Loader.loadPDF(encrypted, "wrong-password"));
        try (PDDocument document = Loader.loadPDF(encrypted, "user-password")) {
            assertTrue(document.getCurrentAccessPermission().canPrint());
        }
    }

    private static byte[] simplePdf() throws Exception {
        try (PDDocument document = new PDDocument(); ByteArrayOutputStream output = new ByteArrayOutputStream()) {
            document.addPage(new PDPage());
            document.save(output);
            return output.toByteArray();
        }
    }
}
