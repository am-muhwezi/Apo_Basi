
import React from 'react';

type Role = 'parent' | 'driver' | 'admin' | 'assistant';

interface Props {
  role: Role;
}

const LivePreview: React.FC<Props> = ({ role }) => {
  const renderContent = () => {
    switch (role) {
      case 'parent':
        return (
          <div className="flex flex-col md:flex-row gap-8 items-center">
            <div className="flex-1 space-y-6">
              <div className="bg-blue-50 p-6 rounded-2xl border-l-4 border-blue-600">
                <h4 className="font-bold text-blue-900 text-lg">Real-Time Alerts</h4>
                <p className="text-blue-800 mt-1">"The school bus is 3 minutes away from your stop. Get ready!"</p>
              </div>
              <ul className="space-y-4">
                <li className="flex items-start space-x-3">
                  <div className="bg-green-100 p-1 rounded-full mt-1">
                    <svg className="w-4 h-4 text-green-600" fill="currentColor" viewBox="0 0 20 20"><path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" /></svg>
                  </div>
                  <span className="text-slate-700"><strong>Journey Start:</strong> Notification when the trip begins.</span>
                </li>
                <li className="flex items-start space-x-3">
                  <div className="bg-green-100 p-1 rounded-full mt-1">
                    <svg className="w-4 h-4 text-green-600" fill="currentColor" viewBox="0 0 20 20"><path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" /></svg>
                  </div>
                  <span className="text-slate-700"><strong>Onboarded Status:</strong> Immediate alert when your child scans onto the bus.</span>
                </li>
                <li className="flex items-start space-x-3">
                  <div className="bg-green-100 p-1 rounded-full mt-1">
                    <svg className="w-4 h-4 text-green-600" fill="currentColor" viewBox="0 0 20 20"><path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" /></svg>
                  </div>
                  <span className="text-slate-700"><strong>Live Map:</strong> Watch the bus navigate through traffic in real-time.</span>
                </li>
              </ul>
            </div>
            <div className="w-full md:w-80 bg-slate-900 rounded-[3rem] p-4 shadow-2xl border-8 border-slate-800">
               <div className="bg-white h-[500px] rounded-[2.5rem] overflow-hidden flex flex-col">
                  <div className="bg-blue-600 p-6 text-white text-center font-bold">ApoBasi Parent App</div>
                  <div className="flex-grow bg-slate-100 relative overflow-hidden">
                    {/* Simulated Map */}
                    <img src="https://picsum.photos/id/120/400/800" className="w-full h-full object-cover opacity-50" />
                    <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 animate-bounce">
                       <div className="bg-blue-600 p-2 rounded-full shadow-lg">
                          <svg className="w-6 h-6 text-white" fill="currentColor" viewBox="0 0 20 20"><path d="M10 2a6 6 0 00-6 6c0 1.88.62 3.54 1.67 4.96L10 18l4.33-5.04C15.38 11.54 16 9.88 16 8a6 6 0 00-6-6zm0 8a2 2 0 110-4 2 2 0 010 4z"/></svg>
                       </div>
                    </div>
                  </div>
                  <div className="p-4 bg-white border-t space-y-2">
                     <p className="text-sm font-bold text-slate-900">Bus KBC 123Z - Route A</p>
                     <p className="text-xs text-slate-500">Status: En route to Pick-up Point</p>
                     <div className="w-full bg-slate-200 h-1.5 rounded-full overflow-hidden">
                       <div className="bg-blue-600 h-full w-[65%]"></div>
                     </div>
                     <p className="text-[10px] text-right text-slate-400">ETA: 4 mins</p>
                  </div>
               </div>
            </div>
          </div>
        );
      case 'driver':
        return (
          <div className="flex flex-col md:flex-row-reverse gap-8 items-center">
            <div className="flex-1 space-y-6">
              <h4 className="text-2xl font-bold text-slate-900">Driving with Confidence</h4>
              <p className="text-slate-600">The driver app simplifies every trip, allowing focus on the road while we handle the data.</p>
              <div className="grid grid-cols-2 gap-4">
                <div className="p-4 bg-slate-50 rounded-xl">
                  <p className="text-xs text-slate-500 uppercase">Current Route</p>
                  <p className="font-bold">Westlands - Loop 2</p>
                </div>
                <div className="p-4 bg-slate-50 rounded-xl">
                  <p className="text-xs text-slate-500 uppercase">Student Count</p>
                  <p className="font-bold">34 Students</p>
                </div>
              </div>
              <ul className="space-y-3">
                <li className="flex items-center space-x-2 text-slate-700">
                  <span className="w-2 h-2 bg-blue-600 rounded-full"></span>
                  <span>One-tap trip initiation with GPS sync.</span>
                </li>
                <li className="flex items-center space-x-2 text-slate-700">
                  <span className="w-2 h-2 bg-blue-600 rounded-full"></span>
                  <span>Turn-by-turn navigation for assigned routes.</span>
                </li>
                <li className="flex items-center space-x-2 text-slate-700">
                  <span className="w-2 h-2 bg-blue-600 rounded-full"></span>
                  <span>Offline mode for low-connectivity areas.</span>
                </li>
              </ul>
            </div>
            <div className="w-full md:w-80 bg-slate-900 rounded-[3rem] p-4 shadow-2xl border-8 border-slate-800">
               <div className="bg-white h-[500px] rounded-[2.5rem] overflow-hidden flex flex-col">
                  <div className="bg-slate-800 p-4 text-white font-bold flex justify-between items-center">
                    <span>ApoBasi Driver</span>
                    <span className="bg-green-500 w-3 h-3 rounded-full"></span>
                  </div>
                  <div className="flex-grow p-4 bg-slate-50 flex flex-col justify-between">
                    <div className="bg-white p-4 rounded-xl shadow-sm border border-slate-100">
                      <p className="text-sm font-bold">Upcoming Stop</p>
                      <p className="text-xs text-slate-500">Nairobi Academy Gate 2</p>
                      <div className="mt-4 flex justify-between text-xs font-bold text-blue-600">
                        <span>4 mins away</span>
                        <span>0.8 km</span>
                      </div>
                    </div>
                    <div className="space-y-4">
                       <button className="w-full py-4 bg-blue-600 text-white rounded-xl font-bold text-lg shadow-lg">
                          START TRIP
                       </button>
                    </div>
                  </div>
               </div>
            </div>
          </div>
        );
      case 'assistant':
        return (
          <div className="flex flex-col md:flex-row gap-8 items-center">
            <div className="flex-1 space-y-6">
              <h4 className="text-2xl font-bold text-slate-900">Seamless Attendance Tracking</h4>
              <p className="text-slate-600">Purely for accountability. Assistants ensure no child is left behind or dropped at the wrong point.</p>
              <div className="bg-white border border-slate-200 rounded-2xl overflow-hidden">
                <table className="min-w-full divide-y divide-slate-200">
                  <thead className="bg-slate-50">
                    <tr>
                      <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase">Student Name</th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase">Action</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-200">
                    <tr>
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-slate-900">David Mwangi</td>
                      <td className="px-6 py-4"><span className="px-2 py-1 bg-green-100 text-green-700 rounded text-xs">Onboarded</span></td>
                    </tr>
                    <tr>
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-slate-900">Sarah Otieno</td>
                      <td className="px-6 py-4"><button className="px-2 py-1 bg-blue-600 text-white rounded text-xs">Confirm</button></td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
            <div className="hidden lg:block w-72 h-72 bg-blue-600 rounded-full flex items-center justify-center relative overflow-hidden">
               <div className="absolute inset-0 bg-blue-500 opacity-20 transform scale-150 rotate-45"></div>
               <svg className="w-32 h-32 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4" />
               </svg>
            </div>
          </div>
        );
      case 'admin':
        return (
          <div className="space-y-8">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
                <h5 className="text-slate-500 font-bold uppercase text-xs mb-2">Active Fleet</h5>
                <div className="flex items-end justify-between">
                  <span className="text-3xl font-extrabold text-slate-900">12</span>
                  <span className="text-green-500 text-sm font-bold">100% Active</span>
                </div>
              </div>
              <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
                <h5 className="text-slate-500 font-bold uppercase text-xs mb-2">In Transit Students</h5>
                <div className="flex items-end justify-between">
                  <span className="text-3xl font-extrabold text-slate-900">428</span>
                  <span className="text-blue-500 text-sm font-bold">Morning Shifts</span>
                </div>
              </div>
              <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
                <h5 className="text-slate-500 font-bold uppercase text-xs mb-2">Pending Alerts</h5>
                <div className="flex items-end justify-between">
                  <span className="text-3xl font-extrabold text-slate-900">0</span>
                  <span className="text-slate-400 text-sm font-bold">All clear</span>
                </div>
              </div>
            </div>
            <div className="bg-slate-900 rounded-3xl p-6 h-96 relative overflow-hidden">
               <div className="absolute inset-0 opacity-40">
                  <img src="https://picsum.photos/id/124/1200/800" className="w-full h-full object-cover" />
               </div>
               <div className="relative z-10">
                 <div className="flex justify-between items-center text-white mb-4">
                   <h5 className="font-bold text-lg">Central Operations Map</h5>
                   <button className="bg-blue-600 px-4 py-1.5 rounded-lg text-xs font-bold">Full Screen View</button>
                 </div>
                 <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                    {[1, 2, 3].map(i => (
                      <div key={i} className="bg-white/95 p-3 rounded-xl shadow-lg border-l-4 border-green-500">
                        <p className="text-[10px] text-slate-500 font-bold uppercase">Bus 0{i}</p>
                        <p className="text-xs font-bold text-slate-900">Mombasa Rd Area</p>
                        <p className="text-[10px] text-green-600 mt-1">Normal Speed: 45km/h</p>
                      </div>
                    ))}
                 </div>
               </div>
            </div>
          </div>
        );
      default:
        return null;
    }
  };

  return (
    <div className="mt-12 bg-slate-50 rounded-[2.5rem] p-8 md:p-12 border border-slate-100 min-h-[600px] flex flex-col justify-center">
      {renderContent()}
    </div>
  );
};

export default LivePreview;
