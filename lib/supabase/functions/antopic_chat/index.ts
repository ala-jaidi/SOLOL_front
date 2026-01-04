// supabase/functions/antopic_chat/index.ts
// Lightweight chat proxy stub with CORS + optional SSE streaming
// It echoes a helpful assistant reply so the app pipeline works end-to-end.
// Replace the echo with a real LLM call later (OpenAI, etc.).

const CORS_HEADERS = {
  "access-control-allow-origin": "*",
  "access-control-allow-headers": "authorization, x-client-info, apikey, content-type",
  "access-control-allow-methods": "POST, OPTIONS",
  "access-control-max-age": "86400",
};

function jsonResponse(body: unknown, init: ResponseInit = {}) {
  return new Response(JSON.stringify(body), {
    ...init,
    headers: {
      "content-type": "application/json; charset=utf-8",
      ...CORS_HEADERS,
      ...(init.headers || {}),
    },
  });
}

export const handler = async (req: Request): Promise<Response> => {
  // CORS preflight
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS_HEADERS });
  if (req.method !== "POST") return jsonResponse({ error: "Method not allowed" }, { status: 405 });

  let payload: any;
  try {
    payload = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, { status: 400 });
  }

  const message: string = typeof payload?.message === "string" ? payload.message.trim() : "";
  const stream: boolean = Boolean(payload?.stream);
  const sessionId: string | undefined = payload?.session_id;
  const templateKey: string | undefined = payload?.template_key;

  // Build a friendly dummy reply
  const baseReply = message
    ? `Bonjour! Voici une réponse à votre message: "${message}".`
    : "Bonjour! Je suis votre assistant. Posez votre question.";
  const reply = `${baseReply} (session: ${sessionId ?? "-"}, template: ${templateKey ?? "default"})`;

  if (!stream) {
    return jsonResponse({ reply });
  }

  // SSE streaming: send the reply in chunks
  const encoder = new TextEncoder();
  const parts = reply.match(/.{1,24}/g) ?? [reply];

  const streamBody = new ReadableStream<Uint8Array>({
    async start(controller) {
      // Initial keep-alive/comment to establish stream quickly
      controller.enqueue(encoder.encode(": connected\n\n"));
      for (const chunk of parts) {
        const line = `data: ${JSON.stringify({ delta: chunk })}\n\n`;
        controller.enqueue(encoder.encode(line));
        // Small pacing so UI can render progressively
        await new Promise((r) => setTimeout(r, 50));
      }
      controller.enqueue(encoder.encode("data: [DONE]\n\n"));
      controller.close();
    },
  });

  return new Response(streamBody, {
    headers: {
      ...CORS_HEADERS,
      "content-type": "text/event-stream; charset=utf-8",
      "cache-control": "no-cache",
      connection: "keep-alive",
    },
  });
};

// Deno deploy/serve
// @ts-ignore - Edge functions export default per Supabase runtime
export default handler;
