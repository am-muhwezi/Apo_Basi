import Navbar from '../../components/landing/Navbar';
import Footer from '../../components/landing/Footer';

export default function PrivacyPage() {
  return (
    <div className="min-h-screen bg-gray-950">
      <Navbar />
      <main className="pt-24 pb-16">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
          <h1 className="text-4xl font-bold text-white mb-8">Privacy Policy</h1>

          <div className="prose prose-invert max-w-none">
            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-white mb-4">Introduction</h2>
              <p className="text-gray-300 leading-relaxed">
                ApoBasi ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our school bus tracking and attendance management platform.
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-white mb-4">Information We Collect</h2>
              <p className="text-gray-300 leading-relaxed mb-4">
                We collect information that you provide directly to us, including:
              </p>
              <ul className="list-disc list-inside text-gray-300 space-y-2">
                <li>Account information (name, email, phone number)</li>
                <li>Student information (name, school, grade)</li>
                <li>Location data (GPS coordinates for bus tracking)</li>
                <li>Attendance records</li>
                <li>Communication data (messages, notifications)</li>
              </ul>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-white mb-4">How We Use Your Information</h2>
              <p className="text-gray-300 leading-relaxed mb-4">
                We use the information we collect to:
              </p>
              <ul className="list-disc list-inside text-gray-300 space-y-2">
                <li>Provide real-time bus tracking services</li>
                <li>Manage student attendance</li>
                <li>Send notifications about bus arrivals and departures</li>
                <li>Improve our services and user experience</li>
                <li>Ensure the safety and security of students</li>
              </ul>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-white mb-4">Data Security</h2>
              <p className="text-gray-300 leading-relaxed">
                We implement appropriate technical and organizational measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction. All data is encrypted in transit and at rest.
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-white mb-4">Your Rights</h2>
              <p className="text-gray-300 leading-relaxed mb-4">
                You have the right to:
              </p>
              <ul className="list-disc list-inside text-gray-300 space-y-2">
                <li>Access your personal information</li>
                <li>Correct inaccurate data</li>
                <li>Request deletion of your data</li>
                <li>Object to processing of your data</li>
                <li>Data portability</li>
              </ul>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-white mb-4">Contact Us</h2>
              <p className="text-gray-300 leading-relaxed">
                If you have questions about this Privacy Policy, please contact us at:
                <br />
                <a href="mailto:privacy@apobasi.com" className="text-blue-400 hover:text-blue-300">
                  privacy@apobasi.com
                </a>
              </p>
            </section>

            <p className="text-gray-500 text-sm mt-12">
              Last updated: January 2026
            </p>
          </div>
        </div>
      </main>
      <Footer />
    </div>
  );
}
