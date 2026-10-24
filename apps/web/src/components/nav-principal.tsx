"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

const DESTINOS = [
  { href: "/", rotulo: "Resumo" },
  { href: "/transacoes", rotulo: "Transações" },
  { href: "/parcelamentos", rotulo: "Parcelamentos" },
  { href: "/cadastros", rotulo: "Cadastros" },
];

export function NavPrincipal() {
  const pathname = usePathname();
  return (
    <nav
      aria-label="Principal"
      className="fixed inset-x-0 bottom-0 z-10 flex justify-around border-t border-foreground/15 bg-background md:static md:justify-start md:gap-1 md:border-0"
    >
      {DESTINOS.map(({ href, rotulo }) => {
        const ativo = href === "/" ? pathname === "/" : pathname.startsWith(href);
        return (
          <Link
            key={href}
            href={href}
            aria-current={ativo ? "page" : undefined}
            className={`px-3 py-3 text-sm md:rounded-md md:py-1.5 ${
              ativo ? "font-semibold underline underline-offset-4" : "hover:bg-foreground/5"
            }`}
          >
            {rotulo}
          </Link>
        );
      })}
    </nav>
  );
}
