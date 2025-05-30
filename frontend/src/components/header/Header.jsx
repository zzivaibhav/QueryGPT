import React from 'react';
 
export default function Header() {
  return (
    <header className="fixed top-0 left-0 right-0 bg-white dark:bg-gray-800 shadow-md z-50">
      <div className="max-w-7xl mx-auto px-4 py-3 flex justify-between items-center">
        <h1 className="text-2xl font-bold text-purple-600 dark:text-purple-400">
          QueryGPT
        </h1>
        <ThemeToggle />
      </div>
    </header>
  );
}
