
import React from 'react';

const Hero: React.FC = () => {
  return (
    <div className="relative overflow-hidden bg-white pt-16 pb-32">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="lg:grid lg:grid-cols-12 lg:gap-8 items-center">
          <div className="sm:text-center md:max-w-2xl md:mx-auto lg:col-span-6 lg:text-left">
            <h1 className="text-4xl tracking-tight font-extrabold text-slate-900 sm:text-5xl md:text-6xl lg:text-5xl xl:text-6xl leading-tight">
              <span className="block">Safety on the way,</span>
              <span className="block text-blue-600">Peace of mind at home.</span>
            </h1>
            <p className="mt-3 text-base text-slate-600 sm:mt-5 sm:text-xl lg:text-lg xl:text-xl">
              ApoBasi is East Africa's leading school transport management system. Real-time GPS tracking, attendance verification, and fleet monitoring—all in one smart platform.
            </p>
            <div className="mt-8 sm:max-w-lg sm:mx-auto sm:text-center lg:text-left lg:mx-0">
              <div className="flex flex-col sm:flex-row gap-4">
                <a href="#contact" className="flex items-center justify-center px-8 py-4 border border-transparent text-base font-bold rounded-xl text-white bg-blue-600 hover:bg-blue-700 shadow-xl transition-all hover:-translate-y-1">
                  Start Your Pilot Program
                </a>
                <a href="#roles" className="flex items-center justify-center px-8 py-4 border border-slate-200 text-base font-bold rounded-xl text-slate-700 bg-slate-50 hover:bg-slate-100 transition-all">
                  Watch the Demo
                </a>
              </div>
              <p className="mt-4 text-sm text-slate-500 italic">
                Trusted by 150+ schools in Nairobi, Kampala, and Dar es Salaam.
              </p>
            </div>
          </div>
          <div className="mt-12 relative sm:max-w-lg sm:mx-auto lg:mt-0 lg:max-w-none lg:mx-0 lg:col-span-6 lg:flex lg:items-center">
            <div className="relative mx-auto w-full rounded-3xl shadow-2xl overflow-hidden ring-8 ring-blue-50">
              <img
                className="w-full object-cover"
                src="https://picsum.photos/id/101/800/600"
                alt="School bus tracking dashboard preview"
              />
              <div className="absolute inset-0 flex items-center justify-center bg-black/20">
                 <button className="bg-white/90 p-4 rounded-full shadow-lg hover:scale-110 transition-transform">
                   <svg className="w-12 h-12 text-blue-600" fill="currentColor" viewBox="0 0 20 20">
                     <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM9.555 7.168A1 1 0 008 8v4a1 1 0 001.555.832l3-2a1 1 0 000-1.664l-3-2z" clipRule="evenodd" />
                   </svg>
                 </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Hero;
