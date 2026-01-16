import Navbar from '../../components/landing/Navbar';
import Footer from '../../components/landing/Footer';

export default function TermsPage() {
  return (
    <div className="min-h-screen bg-gray-950">
      <Navbar />
      <main className="pt-24 pb-16">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
          <h1 className="text-4xl font-bold text-white mb-8">Terms of Service</h1>

          <div className="prose prose-invert max-w-none">
            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-white mb-4">1. Acceptance of Terms</h2>
              <p className="text-gray-300 leading-relaxed">
                By accessing and using ApoBasi's services, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use our services.
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-white mb-4">2. Description of Service</h2>
              <p className="text-gray-300 leading-relaxed">
                ApoBasi provides a school bus tracking and attendance management platform designed for schools, parents, drivers, and bus minders. Our services include real-time GPS tracking, digital attendance management, and parent notifications.
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-white mb-4">3. User Responsibilities</h2>
              <p className="text-gray-300 leading-relaxed mb-4">
                You agree to:
              </p>
              <ul className="list-disc list-inside text-gray-300 space-y-2">
                <li>Provide accurate and complete information</li>
                <li>Maintain the security of your account credentials</li>
                <li>Use the service only for lawful purposes</li>
                <li>Not interfere with or disrupt the service</li>
                <li>Comply with all applicable laws and regulations</li>
              </ul>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-white mb-4">4. Privacy and Data Protection</h2>
              <p className="text-gray-300 leading-relaxed">
                Your use of ApoBasi is also governed by our Privacy Policy. We are committed to protecting your personal information and complying with applicable data protection laws.
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-white mb-4">5. Service Availability</h2>
              <p className="text-gray-300 leading-relaxed">
                While we strive to provide continuous service, we do not guarantee that ApoBasi will be available at all times. We reserve the right to modify, suspend, or discontinue the service at any time.
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-white mb-4">6. Limitation of Liability</h2>
              <p className="text-gray-300 leading-relaxed">
                ApoBasi shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use or inability to use the service.
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-white mb-4">7. Changes to Terms</h2>
              <p className="text-gray-300 leading-relaxed">
                We reserve the right to modify these Terms of Service at any time. We will notify users of significant changes via email or through the service.
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-white mb-4">8. Contact Information</h2>
              <p className="text-gray-300 leading-relaxed">
                For questions about these Terms of Service, please contact us at:
                <br />
                <a href="mailto:legal@apobasi.com" className="text-blue-400 hover:text-blue-300">
                  legal@apobasi.com
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
