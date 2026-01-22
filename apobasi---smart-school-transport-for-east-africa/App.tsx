
import React, { useState, useEffect } from 'react';
import Header from './components/Header';
import Hero from './components/Hero';
import Features from './components/Features';
import RoleSelector from './components/RoleSelector';
import HowItWorks from './components/HowItWorks';
import LivePreview from './components/LivePreview';
import ContactDemo from './components/ContactDemo';
import Footer from './components/Footer';

const App: React.FC = () => {
  const [activeRole, setActiveRole] = useState<'parent' | 'driver' | 'admin' | 'assistant'>('parent');

  return (
    <div className="min-h-screen flex flex-col">
      <Header />
      
      <main className="flex-grow">
        <Hero />
        
        {/* Statistics Bar */}
        <div className="bg-white border-y border-slate-100 py-12">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div className="grid grid-cols-2 md:grid-cols-4 gap-8 text-center">
              <div>
                <p className="text-4xl font-extrabold text-blue-600">150+</p>
                <p className="text-slate-500 mt-2 font-medium">Schools in Kenya & Uganda</p>
              </div>
              <div>
                <p className="text-4xl font-extrabold text-blue-600">12,000+</p>
                <p className="text-slate-500 mt-2 font-medium">Safe Commutes Daily</p>
              </div>
              <div>
                <p className="text-4xl font-extrabold text-blue-600">99.9%</p>
                <p className="text-slate-500 mt-2 font-medium">Uptime Tracking</p>
              </div>
              <div>
                <p className="text-4xl font-extrabold text-blue-600">350+</p>
                <p className="text-slate-500 mt-2 font-medium">Verified Drivers</p>
              </div>
            </div>
          </div>
        </div>

        <section id="features" className="py-20 bg-slate-50">
          <Features />
        </section>

        <section id="roles" className="py-20 bg-white">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div className="text-center mb-16">
              <h2 className="text-3xl font-extrabold text-slate-900 sm:text-4xl">
                A Unified Ecosystem for Safety
              </h2>
              <p className="mt-4 text-xl text-slate-600">
                Specialized interfaces for every stakeholder in the school transport journey.
              </p>
            </div>
            
            <RoleSelector activeRole={activeRole} onRoleChange={setActiveRole} />
            
            <div className="mt-12">
               <LivePreview role={activeRole} />
            </div>
          </div>
        </section>

        <section id="how-it-works" className="py-20 bg-slate-50">
          <HowItWorks />
        </section>

        <section id="contact" className="py-20 bg-white">
          <ContactDemo />
        </section>
      </main>

      <Footer />
    </div>
  );
};

export default App;
