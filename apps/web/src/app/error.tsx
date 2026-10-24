"use client";

export default function Error({ retry }: { error: unknown; retry: () => void }) {
  return (
    <div role="alert" className="rounded-lg border border-red-500/40 p-6">
      <h1 className="mb-2 text-xl font-semibold">Não foi possível carregar esta página.</h1>
      <p className="mb-4 text-foreground/70">Algo deu errado. Tente de novo.</p>
      <button
        type="button"
        onClick={() => retry()}
        className="rounded-md border border-foreground/30 px-3 py-1.5 text-sm hover:bg-foreground/5"
      >
        Tentar de novo
      </button>
    </div>
  );
}
