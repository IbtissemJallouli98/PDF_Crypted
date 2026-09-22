package com.tb2si.pdf;

import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.encryption.AccessPermission;
import org.apache.pdfbox.pdmodel.encryption.StandardProtectionPolicy;

import java.io.ByteArrayOutputStream;
import java.io.IOException;

final class PdfEncryptionService {
    private final int maxPdfBytes;

    PdfEncryptionService(int maxPdfBytes) {
        this.maxPdfBytes = maxPdfBytes;
    }

    byte[] encrypt(byte[] sourcePdf, String userPassword, String ownerPassword) throws IOException {
        if (sourcePdf == null || sourcePdf.length == 0 || sourcePdf.length > maxPdfBytes) {
            throw new IllegalArgumentException("PDF size is not allowed");
        }
        if (userPassword == null || ownerPassword == null || userPassword.isBlank() || ownerPassword.isBlank()
                || userPassword.equals(ownerPassword) || userPassword.length() > 256 || ownerPassword.length() > 256) {
            throw new IllegalArgumentException("Passwords are not valid");
        }

        AccessPermission permissions = new AccessPermission();
        permissions.setCanPrint(true);
        permissions.setCanModify(false);
        permissions.setCanModifyAnnotations(false);
        permissions.setCanFillInForm(false);
        permissions.setCanAssembleDocument(false);
        permissions.setCanExtractContent(false);
        permissions.setCanExtractForAccessibility(false);

        StandardProtectionPolicy policy = new StandardProtectionPolicy(ownerPassword, userPassword, permissions);
        policy.setEncryptionKeyLength(256);
        policy.setPreferAES(true);

        try (PDDocument document = Loader.loadPDF(sourcePdf);
             ByteArrayOutputStream output = new ByteArrayOutputStream(sourcePdf.length + 1024)) {
            document.protect(policy);
            document.save(output);
            return output.toByteArray();
        }
    }
}
