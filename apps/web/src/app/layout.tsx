import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import { Suspense } from "react";
import { CompetenciaPicker } from "@/components/competencia-picker";
import { NavPrincipal } from "@/components/nav-principal";
import {
  BotaoNovaTransacao,
  MesPadraoSync,
  TransacaoDrawerProvider,
} from "@/components/transacao-drawer";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "Controle de Gastos",
  description: "Controle de gastos pessoais",
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html
      lang="pt-BR"
      className={`${geistSans.variable} ${geistMono.variable} h-full antialiased`}
    >
      <body className="min-h-full flex flex-col">
        <TransacaoDrawerProvider>
        <header className="border-b border-foreground/15">
          <div className="mx-auto flex w-full max-w-5xl flex-wrap items-center justify-between gap-x-6 gap-y-2 px-4 py-2">
            <span className="font-semibold">Controle de Gastos</span>
            <Suspense fallback={null}>
              <NavPrincipal />
            </Suspense>
            <Suspense fallback={null}>
              <CompetenciaPicker />
              <MesPadraoSync />
            </Suspense>
            <BotaoNovaTransacao />
          </div>
        </header>
        <main className="mx-auto w-full max-w-5xl flex-1 px-4 py-6 pb-20 md:pb-6">
          {children}
        </main>
        </TransacaoDrawerProvider>
      </body>
    </html>
  );
}
