import Navbar from '../../components/landing/Navbar';
import Footer from '../../components/landing/Footer';

export default function PrivacyPage() {
  return (
    <div className="min-h-screen bg-gray-50 text-gray-900 dark:bg-gray-950 dark:text-white">
      <Navbar />
      <main className="pt-24 pb-16">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
          <h1 className="text-4xl font-bold text-gray-900 dark:text-white mb-8">Privacy Policy</h1>

          <div className="prose max-w-none dark:prose-invert">
            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-gray-900 dark:text-white mb-4">Introduction</h2>
              <p className="text-gray-700 dark:text-gray-300 leading-relaxed">
                ApoBasi ("we", "our", or "us") is committed to protecting user privacy and safeguarding personal data. This Privacy Policy explains how information is collected, used, and protected when using the ApoBasi school bus tracking and attendance management platform.
              </p>
              <p className="text-gray-700 dark:text-gray-300 leading-relaxed mt-4">
                ApoBasi is designed for use by schools, authorized staff, bus drivers, parents, and guardians for the purpose of student transportation safety and attendance management.
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-gray-900 dark:text-white mb-4">Information We Collect</h2>
              <p className="text-gray-700 dark:text-gray-300 leading-relaxed mb-4">
                We collect the following types of information:
              </p>

              <h3 className="text-xl font-semibold text-gray-900 dark:text-white mb-3 mt-6">Account Information</h3>
              <ul className="list-disc list-inside text-gray-700 dark:text-gray-300 space-y-2">
                <li>Name</li>
                <li>Email address</li>
                <li>Phone number</li>
                <li>User role (school admin, driver, parent, bus minder)</li>
              </ul>

              <h3 className="text-xl font-semibold text-gray-900 dark:text-white mb-3 mt-6">Student Information</h3>
              <ul className="list-disc list-inside text-gray-700 dark:text-gray-300 space-y-2">
                <li>Student name</li>
                <li>School affiliation</li>
                <li>Class or grade</li>
                <li>Attendance records</li>
              </ul>

              <h3 className="text-xl font-semibold text-gray-900 dark:text-white mb-3 mt-6">Location Data</h3>
              <ul className="list-disc list-inside text-gray-700 dark:text-gray-300 space-y-2">
                <li>Real-time GPS location data collected only from authorized school bus drivers</li>
                <li>Location data may be collected in the foreground or background during active school trips only</li>
                <li>Parents, guardians, and students do not share their own location data through the ApoBasi platform</li>
              </ul>

              <h3 className="text-xl font-semibold text-gray-900 dark:text-white mb-3 mt-6">Communication Data</h3>
              <ul className="list-disc list-inside text-gray-700 dark:text-gray-300 space-y-2">
                <li>Notifications related to bus arrivals, departures, and attendance updates</li>
              </ul>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-gray-900 dark:text-white mb-4">How We Use Information</h2>
              <p className="text-gray-700 dark:text-gray-300 leading-relaxed mb-4">
                Information collected by ApoBasi is used strictly to:
              </p>
              <ul className="list-disc list-inside text-gray-700 dark:text-gray-300 space-y-2">
                <li>Provide real-time school bus tracking</li>
                <li>Manage and record student attendance</li>
                <li>Notify parents and guardians of bus arrival and departure events</li>
                <li>Improve transportation safety and operational reliability</li>
                <li>Maintain platform security and integrity</li>
              </ul>
              <p className="text-gray-700 dark:text-gray-300 leading-relaxed mt-4">
                Location data is <strong>not</strong> used for:
              </p>
              <ul className="list-disc list-inside text-gray-700 dark:text-gray-300 space-y-2">
                <li>Advertising</li>
                <li>Marketing</li>
                <li>Profiling</li>
                <li>Analytics unrelated to school transportation</li>
              </ul>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-gray-900 dark:text-white mb-4">Location Data Usage and Background Access</h2>
              <p className="text-gray-700 dark:text-gray-300 leading-relaxed mb-4">
                ApoBasi uses background location access only for authorized school bus drivers to enable continuous and accurate tracking during active school trips, even when the app is minimized or the device screen is off.
              </p>
              <p className="text-gray-700 dark:text-gray-300 leading-relaxed mb-4">
                Location tracking:
              </p>
              <ul className="list-disc list-inside text-gray-700 dark:text-gray-300 space-y-2">
                <li>Starts only when a school trip is active</li>
                <li>Stops automatically when the trip ends</li>
                <li>Does not occur outside transportation hours</li>
              </ul>
              <p className="text-gray-700 dark:text-gray-300 leading-relaxed mt-4">
                Location data is never collected unnecessarily or continuously.
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-gray-900 dark:text-white mb-4">Children's Privacy</h2>
              <p className="text-gray-700 dark:text-gray-300 leading-relaxed mb-4">
                ApoBasi supports student safety and is used under the authority of schools and with parental awareness.
              </p>
              <ul className="list-disc list-inside text-gray-700 dark:text-gray-300 space-y-2">
                <li>ApoBasi does not display precise student locations</li>
                <li>ApoBasi does not collect biometric data</li>
                <li>ApoBasi does not use student data for advertising or marketing</li>
                <li>Student data is accessible only to authorized school staff and linked parents or guardians</li>
              </ul>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-gray-900 dark:text-white mb-4">Data Sharing</h2>
              <p className="text-gray-700 dark:text-gray-300 leading-relaxed mb-4">
                ApoBasi does not sell personal data.
              </p>
              <p className="text-gray-700 dark:text-gray-300 leading-relaxed mb-4">
                Data is shared only:
              </p>
              <ul className="list-disc list-inside text-gray-700 dark:text-gray-300 space-y-2">
                <li>With the associated school</li>
                <li>With authorized parents or guardians</li>
                <li>When required by law</li>
              </ul>
              <p className="text-gray-700 dark:text-gray-300 leading-relaxed mt-4">
                No third-party advertising or tracking services access location or student data.
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-gray-900 dark:text-white mb-4">Data Security</h2>
              <p className="text-gray-700 dark:text-gray-300 leading-relaxed mb-4">
                We implement appropriate technical and organizational safeguards to protect personal information, including:
              </p>
              <ul className="list-disc list-inside text-gray-700 dark:text-gray-300 space-y-2">
                <li>Encryption of data in transit and at rest</li>
                <li>Role-based access controls</li>
                <li>Secure authentication mechanisms</li>
              </ul>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-gray-900 dark:text-white mb-4">Data Retention</h2>
              <p className="text-gray-700 dark:text-gray-300 leading-relaxed">
                Location data and attendance records are retained only for as long as necessary to support transportation operations and school requirements, after which they are securely deleted or anonymized.
              </p>
              <p className="text-gray-700 dark:text-gray-300 leading-relaxed mt-4">
                Schools may request data deletion in accordance with applicable laws.
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-gray-900 dark:text-white mb-4">User Rights</h2>
              <p className="text-gray-700 dark:text-gray-300 leading-relaxed mb-4">
                Users may request to:
              </p>
              <ul className="list-disc list-inside text-gray-700 dark:text-gray-300 space-y-2">
                <li>Access their personal information</li>
                <li>Correct inaccurate data</li>
                <li>Request deletion of personal data</li>
                <li>Object to certain data processing</li>
                <li>Request data portability where applicable</li>
              </ul>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-gray-900 dark:text-white mb-4">Contact Information</h2>
              <p className="text-gray-700 dark:text-gray-300 leading-relaxed">
                For privacy-related inquiries, contact:
                <br />
                📧 <a href="mailto:privacy@apobasi.com" className="text-blue-600 hover:text-blue-500 dark:text-blue-400 dark:hover:text-blue-300">
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
