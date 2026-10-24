export function EstadoVazio({ children }: { children: React.ReactNode }) {
  return (
    <p className="rounded-lg border border-dashed border-foreground/25 p-8 text-center text-foreground/70">
      {children}
    </p>
  );
}
