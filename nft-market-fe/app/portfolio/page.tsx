"use client";

// import { Header } from "./components/header";
import { Sidebar } from "./components/sidebar";
import { MainContent } from "./components/main-content";
import { WarningBanner } from "./components/warning-banner";

export default function Home() {
  return (
    <div className="flex flex-col min-h-screen">
      {/* <Header /> */}
      {/* <WarningBanner /> */}
      <div className="flex flex-1">
        <Sidebar />
        <MainContent />
      </div>
    </div>
  );
}
