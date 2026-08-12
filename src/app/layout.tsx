import type { Metadata } from "next";
import "./styles.css";

export const metadata: Metadata = {
  title: "AFTiFest Mission Control",
  description: "Governed operational command center for AfroFutureTech iFest.",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
