package com.tb2si.pdf;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.sun.net.httpserver.HttpServer;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.util.concurrent.Executors;

public final class Application {
    private Application() {}

    public static void main(String[] args) throws IOException {
        ServiceConfig config = ServiceConfig.fromEnvironment();
        ObjectMapper mapper = new ObjectMapper();
        PdfEncryptionService encryptionService = new PdfEncryptionService(config.maxPdfBytes());

        HttpServer server = HttpServer.create(new InetSocketAddress(config.port()), 0);
        server.createContext("/healthz", new HealthHandler(mapper));
        server.createContext("/v1/pdf/encrypt", new EncryptHandler(config, mapper, encryptionService));
        server.setExecutor(Executors.newFixedThreadPool(config.workerThreads()));
        Runtime.getRuntime().addShutdownHook(new Thread(() -> server.stop(0)));
        server.start();
        System.out.println("PDF encryption service listening on port " + config.port());
    }
}
