package net.kantharos.certharbor.client.smoke;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

import net.kantharos.certharbor.client.api.SessionApi;
import net.kantharos.certharbor.client.invoker.ApiClient;
import net.kantharos.certharbor.client.model.SessionBody;
import com.sun.net.httpserver.HttpServer;
import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * Hand-written smoke test (not generator output): proves the generated client can actually
 * drive a real operation end to end — build a request, send it over java.net.http, and
 * deserialize a real response — rather than merely compiling. It never touches a live backend;
 * it stubs one operation ({@code GET /api/v1/session}) with the JDK's built-in HttpServer, the
 * same "no running backend" posture as generation itself (D4/D8).
 */
class SessionApiSmokeTest {

    private HttpServer server;

    @BeforeEach
    void startStubServer() throws IOException {
        server = HttpServer.create(new InetSocketAddress("localhost", 0), 0);
        server.createContext("/api/v1/session", exchange -> {
            byte[] body = ("{\"state\":\"authenticated\","
                    + "\"user\":{\"username\":\"alice\",\"role\":\"admin\"}}")
                    .getBytes(StandardCharsets.UTF_8);
            exchange.getResponseHeaders().add("Content-Type", "application/json");
            exchange.sendResponseHeaders(200, body.length);
            exchange.getResponseBody().write(body);
            exchange.close();
        });
        server.start();
    }

    @AfterEach
    void stopStubServer() {
        server.stop(0);
    }

    @Test
    void getSessionDeserializesARealResponse() throws Exception {
        ApiClient apiClient = new ApiClient();
        apiClient.updateBaseUri("http://localhost:" + server.getAddress().getPort());

        SessionApi sessionApi = new SessionApi(apiClient);
        SessionBody session = sessionApi.getSession();

        assertNotNull(session);
        assertEquals(SessionBody.StateEnum.AUTHENTICATED, session.getState());
        assertNotNull(session.getUser());
        assertEquals("alice", session.getUser().getUsername());
    }
}
