import { EstadoVazio } from "@/components/estado-vazio";

export default function Transacoes() {
  return (
    <>
      <h1 className="mb-4 text-2xl font-semibold">Transações</h1>
      <EstadoVazio>Nenhuma transação neste mês.</EstadoVazio>
    </>
  );
}
