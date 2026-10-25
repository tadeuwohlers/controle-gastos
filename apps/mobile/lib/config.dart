/// URL da API, informada no build: `--dart-define=API_URL=http://<host>:8000`.
/// Só a origem; os paths já incluem `/api/v1`.
const apiUrl = String.fromEnvironment('API_URL');
