
import React from 'react';

const steps = [
  {
    number: '01',
    title: 'School Onboarding',
    description: 'The school signs up and adds bus details, routes, and creates login credentials for drivers and assistants.'
  },
  {
    number: '02',
    title: 'Parent Registration',
    description: 'Administrators invite parents via SMS or email. Parents download the ApoBasi app to connect with their child profile.'
  },
  {
    number: '03',
    title: 'Start Tracking',
    description: 'Drivers start their trip, assistants scan students, and parents track the entire journey in real-time.'
  }
];

const HowItWorks: React.FC = () => {
  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div className="text-center mb-16">
        <h2 className="text-3xl font-extrabold text-slate-900 sm:text-4xl">Implementing ApoBasi is simple</h2>
        <p className="mt-4 text-xl text-slate-500">We guide you through every step of the digitisation process.</p>
      </div>

      <div className="relative">
        {/* Connector Line */}
        <div className="hidden lg:block absolute top-12 left-0 w-full h-0.5 bg-slate-200"></div>
        
        <div className="grid grid-cols-1 gap-12 lg:grid-cols-3 relative z-10">
          {steps.map((step, idx) => (
            <div key={idx} className="bg-white p-8 rounded-3xl shadow-sm border border-slate-100 text-center lg:text-left">
              <span className="text-5xl font-black text-blue-100 mb-6 block lg:inline-block">{step.number}</span>
              <h3 className="text-2xl font-bold text-slate-900 mb-4">{step.title}</h3>
              <p className="text-slate-600 leading-relaxed">{step.description}</p>
            </div>
          ))}
        </div>
      </div>
      
      <div className="mt-20 p-10 bg-blue-600 rounded-[3rem] text-center text-white">
        <h3 className="text-2xl font-bold mb-4">Want to see it in action?</h3>
        <p className="text-blue-100 mb-8 max-w-2xl mx-auto">We offer a free 14-day trial for qualified schools across East Africa. Let's make transport safer together.</p>
        <button className="bg-white text-blue-600 px-10 py-4 rounded-2xl font-bold hover:bg-slate-50 transition-colors shadow-xl">
          Request a Physical Demo
        </button>
      </div>
    </div>
  );
};

export default HowItWorks;
