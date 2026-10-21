import createClient from "openapi-fetch";

import type { paths } from "./schema";

const apiUrl = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8000/api/v1";

// Os paths do schema já incluem o prefixo /api/v1, então o baseUrl é só a origem.
export const api = createClient<paths>({
  baseUrl: new URL(apiUrl).origin,
});
