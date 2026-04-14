import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "My Personal Page",
  description: "A customizable personal page powered by myinfo.json",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
