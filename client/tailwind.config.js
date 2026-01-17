/** @type {import('tailwindcss').Config} */
export default {
  darkMode: 'class',
  content: [
    './index.html',
    './src/**/*.{js,ts,jsx,tsx}',
    './src/pages/landing/**/*.{js,ts,jsx,tsx}',
    './src/components/landing/**/*.{js,ts,jsx,tsx}'
  ],
  theme: {
    extend: {
      colors: {
        primary: '#3b82f6',  // Matches landing blue-500
        secondary: '#22c55e'  // Matches landing green-500
      }
    },
  },
  plugins: [],
};
