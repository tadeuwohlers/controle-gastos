"use client";

import { useRouter } from "next/navigation";
import { CriarCategoria, CriarConta } from "@/components/criar-cadastro";

export function NovaConta() {
  const router = useRouter();
  return <CriarConta onCriada={() => router.refresh()} />;
}

export function NovaCategoria() {
  const router = useRouter();
  return <CriarCategoria onCriada={() => router.refresh()} />;
}
