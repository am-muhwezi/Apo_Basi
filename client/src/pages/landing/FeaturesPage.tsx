import Navbar from '../../components/landing/Navbar';
import Footer from '../../components/landing/Footer';
import SectionHeader from '../../components/landing/SectionHeader';
import Card from '../../components/landing/Card';

export default function FeaturesPage() {
  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-950">
      <Navbar />
      <main className="pt-24 pb-16">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <SectionHeader
            badge="Features"
            title="Everything you need to manage school transport"
            description="ApoBasi provides comprehensive tools for schools, parents, drivers, and bus minders."
          />

          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6 mt-12">
            <Card>
              <h3 className="text-xl font-semibold text-gray-900 dark:text-white mb-3">Real-Time Tracking</h3>
              <p className="text-gray-700 dark:text-gray-400">Live GPS tracking of all school buses with sub-second updates.</p>
            </Card>
            <Card>
              <h3 className="text-xl font-semibold text-gray-900 dark:text-white mb-3">Attendance Management</h3>
              <p className="text-gray-700 dark:text-gray-400">Digital check-in/out with offline sync capabilities.</p>
            </Card>
            <Card>
              <h3 className="text-xl font-semibold text-gray-900 dark:text-white mb-3">Parent Notifications</h3>
              <p className="text-gray-700 dark:text-gray-400">Instant alerts for boarding, arrival, and drop-off events.</p>
            </Card>
            <Card>
              <h3 className="text-xl font-semibold text-gray-900 dark:text-white mb-3">Analytics Dashboard</h3>
              <p className="text-gray-700 dark:text-gray-400">Insights on route efficiency and attendance trends.</p>
            </Card>
            <Card>
              <h3 className="text-xl font-semibold text-gray-900 dark:text-white mb-3">Offline-First</h3>
              <p className="text-gray-700 dark:text-gray-400">Works reliably even with poor internet connectivity.</p>
            </Card>
            <Card>
              <h3 className="text-xl font-semibold text-gray-900 dark:text-white mb-3">Secure & Private</h3>
              <p className="text-gray-700 dark:text-gray-400">End-to-end encryption and role-based access control.</p>
            </Card>
          </div>
        </div>
      </main>
      <Footer />
    </div>
  );
}
