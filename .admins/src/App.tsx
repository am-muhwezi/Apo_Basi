import React, { useState } from 'react';
import Sidebar from './components/Sidebar';
import BusesView from './components/BusesView';
import DashboardView from './components/DashboardView';
import RoutesView from './components/RoutesView';
import StudentsView from './components/StudentsView';
import NotificationsView from './components/NotificationsView';

function App() {
  const [activeTab, setActiveTab] = useState('buses');

  const renderContent = () => {
    switch (activeTab) {
      case 'dashboard':
        return <DashboardView />;
      case 'buses':
        return <BusesView />;
      case 'routes':
        return <RoutesView />;
      case 'students':
        return <StudentsView />;
      case 'notifications':
        return <NotificationsView />;
      default:
        return <DashboardView />;
    }
  };

  return (
    <div className="flex h-screen bg-gray-50">
      <Sidebar activeTab={activeTab} onTabChange={setActiveTab} />
      <main className="flex-1 overflow-auto">
        {renderContent()}
      </main>
    </div>
  );
}

export default App;