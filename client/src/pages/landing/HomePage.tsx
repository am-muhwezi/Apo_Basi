import Navbar from '../../components/landing/Navbar';
import Footer from '../../components/landing/Footer';
import Button from '../../components/landing/Button';
import Badge from '../../components/landing/Badge';
import Card from '../../components/landing/Card';
import SectionHeader from '../../components/landing/SectionHeader';

const features = [
  {
    icon: '📍',
    title: 'Real-Time Bus Tracking',
    description: 'Know exactly where the bus is at any moment. Parents get peace of mind with live location updates.',
    badge: 'For Parents',
  },
  {
    icon: '✅',
    title: 'Attendance Management',
    description: 'Digital check-in/out for every student. Bus minders mark attendance even offline.',
    badge: 'For Schools',
  },
  {
    icon: '🔔',
    title: 'Instant Notifications',
    description: 'Get alerts when your child boards, arrives at school, or is dropped off at home.',
    badge: 'For Parents',
  },
  {
    icon: '📊',
    title: 'Analytics Dashboard',
    description: 'Schools get insights on route efficiency, attendance trends, and fleet utilization.',
    badge: 'For Schools',
  },
  {
    icon: '📶',
    title: 'Offline-First Design',
    description: 'Works reliably even with poor connectivity. Data syncs automatically when online.',
    badge: 'Africa-Ready',
  },
  {
    icon: '🔒',
    title: 'Privacy-First Security',
    description: 'End-to-end encryption, role-based access, and GDPR-compliant data handling.',
    badge: 'Secure',
  },
];

const stats = [
  { value: '500+', label: 'Students Tracked' },
  { value: '15+', label: 'Schools Onboarded' },
  { value: '50+', label: 'Daily Trips' },
  { value: '99.9%', label: 'Uptime' },
];

const howItWorks = {
  schools: [
    { step: '1', title: 'Setup', description: 'Upload buses, routes, and student lists to the web dashboard.' },
    { step: '2', title: 'Assign', description: 'Assign drivers and bus minders to each vehicle and route.' },
    { step: '3', title: 'Monitor', description: 'Track all trips in real-time and receive alerts for exceptions.' },
  ],
  parents: [
    { step: '1', title: 'Download', description: 'Install the ApoBasi Parents app and create your account.' },
    { step: '2', title: 'Link', description: "Connect to your child's school using the provided code." },
    { step: '3', title: 'Track', description: 'Get live updates and notifications for every trip.' },
  ],
};

const testimonials = [
  {
    quote: "ApoBasi has completely transformed how we manage school transport. Parents are happier, and we save hours on manual tracking.",
    author: "Sarah K.",
    role: "School Administrator, Kampala",
    avatar: "SK",
  },
  {
    quote: "As a parent, knowing exactly when my children are on the bus and when they'll arrive gives me incredible peace of mind.",
    author: "James M.",
    role: "Parent, Nairobi",
    avatar: "JM",
  },
  {
    quote: "The offline feature is a game-changer. We operate in areas with spotty connectivity, and ApoBasi just works.",
    author: "David O.",
    role: "Transport Manager, Mombasa",
    avatar: "DO",
  },
];

export default function HomePage() {
  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-950">
      <Navbar />

      <main className="pt-16">
        {/* Hero Section */}
        <section className="relative min-h-screen flex items-center bg-white dark:bg-gradient-to-b dark:from-gray-950 dark:to-gray-900 overflow-hidden">
          <div className="absolute inset-0 bg-[url('/grid.svg')] opacity-5 dark:opacity-20"></div>
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-20 relative z-10">
            <div className="grid lg:grid-cols-2 gap-12 items-center">
              <div className="animate-fade-in">
                <Badge variant="info" className="mb-6">Trusted by schools across East Africa</Badge>
                <h1 className="text-4xl sm:text-5xl lg:text-6xl font-extrabold text-gray-900 dark:text-white leading-tight tracking-tight mb-6">
                  Safe, transparent school transport for
                  <span className="bg-gradient-to-r from-blue-400 to-blue-600 bg-clip-text text-transparent"> Africa</span>
                </h1>
                <p className="text-lg text-gray-700 dark:text-gray-300 leading-relaxed mb-8 max-w-xl">
                  ApoBasi helps schools, parents, drivers and bus minders track every child's
                  journey in real time — built for low-network environments in Africa,
                  and across the continent.
                </p>

                <div className="flex flex-wrap gap-3 mb-8">
                  <Badge>Real-time bus tracking</Badge>
                  <Badge>Attendance on & off the bus</Badge>
                  <Badge>Offline-friendly mobile apps</Badge>
                </div>

                <div className="flex flex-wrap gap-4">
                  <Button variant="primary" size="lg" href="#contact">
                    Request a School Demo
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M17 8l4 4m0 0l-4 4m4-4H3" />
                    </svg>
                  </Button>
                  <Button variant="outline" size="lg" href="#how-it-works">
                    See How It Works
                  </Button>
                </div>

                <div className="flex gap-8 mt-10 pt-10 border-t border-gray-200 dark:border-gray-800">
                  <div>
                    <p className="text-2xl font-bold text-gray-900 dark:text-white">For Schools</p>
                    <p className="text-gray-500 text-sm dark:text-gray-400">Simple tools for admins to manage transport</p>
                  </div>
                  <div>
                    <p className="text-2xl font-bold text-gray-900 dark:text-white">For Families</p>
                    <p className="text-gray-500 text-sm dark:text-gray-400">Live tracking and instant notifications</p>
                  </div>
                </div>
              </div>

              {/* Hero Card */}
              <div className="animate-slide-up">
                <Card variant="gradient" className="shadow-2xl">
                  <p className="text-xs uppercase tracking-widest text-gray-400 mb-4">Live Transport Snapshot</p>
                  <div className="grid grid-cols-2 gap-4 mb-6">
                    <div className="bg-gray-100 rounded-xl p-4 border border-gray-200 dark:bg-gray-800/50 dark:border-gray-700/50">
                      <p className="text-gray-400 text-xs mb-1">Buses en route</p>
                      <p className="text-2xl font-bold text-gray-900 dark:text-white">8</p>
                      <Badge variant="success" className="mt-2">On time</Badge>
                    </div>
                    <div className="bg-gray-100 rounded-xl p-4 border border-gray-200 dark:bg-gray-800/50 dark:border-gray-700/50">
                      <p className="text-gray-400 text-xs mb-1">Students today</p>
                      <p className="text-2xl font-bold text-gray-900 dark:text-white">312</p>
                    </div>
                    <div className="bg-gray-100 rounded-xl p-4 border border-gray-200 dark:bg-gray-800/50 dark:border-gray-700/50">
                      <p className="text-gray-400 text-xs mb-1">Parent alerts sent</p>
                      <p className="text-2xl font-bold text-gray-900 dark:text-white">640</p>
                    </div>
                    <div className="bg-gray-100 rounded-xl p-4 border border-gray-200 dark:bg-gray-800/50 dark:border-gray-700/50">
                      <p className="text-gray-400 text-xs mb-1">Network status</p>
                      <p className="text-lg font-semibold text-orange-400">Low-signal ready</p>
                    </div>
                  </div>
                  <p className="text-gray-500 text-xs">
                    Illustrative data. ApoBasi keeps everyone informed, even with unreliable connectivity.
                  </p>
                </Card>
              </div>
            </div>
          </div>
        </section>

        {/* Stats Section */}
        <section className="py-16 bg-gray-100 border-y border-gray-200 dark:bg-gray-900 dark:border-gray-800">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div className="grid grid-cols-2 md:grid-cols-4 gap-8">
              {stats.map((stat) => (
                <div key={stat.label} className="text-center">
                  <p className="text-4xl md:text-5xl font-bold bg-gradient-to-r from-blue-400 to-blue-600 bg-clip-text text-transparent mb-2">{stat.value}</p>
                  <p className="text-gray-600 dark:text-gray-400">{stat.label}</p>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* Features Section */}
        <section id="features" className="py-24 bg-white dark:bg-gray-950">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <SectionHeader
              badge="Features"
              title="One platform for everyone"
              description="ApoBasi is a modular transport and attendance platform. Use the pieces you need today, and grow into advanced features when ready."
            />

            <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
              {features.map((feature) => (
                <Card key={feature.title} className="hover:border-blue-500/30 transition-colors group">
                  <Badge
                    variant={feature.badge === 'For Parents' ? 'info' : feature.badge === 'For Schools' ? 'success' : 'default'}
                    className="mb-4"
                  >
                    {feature.badge}
                  </Badge>
                  <div className="text-3xl mb-4">{feature.icon}</div>
                  <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-2 group-hover:text-blue-400 transition-colors">
                    {feature.title}
                  </h3>
                  <p className="text-gray-600 dark:text-gray-400 text-sm leading-relaxed">{feature.description}</p>
                </Card>
              ))}
            </div>
          </div>
        </section>

        {/* How It Works Section */}
        <section id="how-it-works" className="py-24 bg-gray-50 dark:bg-gray-900">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <SectionHeader
              badge="How It Works"
              title="Simple setup, powerful results"
              description="ApoBasi fits into your existing transport routines. We provide setup support so you can go live quickly with minimal training."
            />

            <div className="grid md:grid-cols-2 gap-12">
              {/* For Schools */}
              <div>
                <h3 className="text-xl font-semibold text-gray-900 dark:text-white mb-6 flex items-center gap-2">
                  <span className="w-8 h-8 rounded-full bg-blue-500/20 flex items-center justify-center text-blue-400 text-sm">🏫</span>
                  For Schools
                </h3>
                <div className="space-y-4">
                  {howItWorks.schools.map((item) => (
                    <div
                      key={item.step}
                      className="flex gap-4 p-4 rounded-xl bg-white border border-gray-200 dark:bg-gray-800/50 dark:border-gray-700/50"
                    >
                      <div className="w-10 h-10 rounded-full bg-gradient-to-r from-blue-500 to-blue-600 flex items-center justify-center text-white font-bold shrink-0">
                        {item.step}
                      </div>
                      <div>
                        <h4 className="font-semibold text-gray-900 dark:text-white mb-1">{item.title}</h4>
                        <p className="text-gray-600 dark:text-gray-400 text-sm">{item.description}</p>
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              {/* For Parents */}
              <div>
                <h3 className="text-xl font-semibold text-gray-900 dark:text-white mb-6 flex items-center gap-2">
                  <span className="w-8 h-8 rounded-full bg-orange-500/20 flex items-center justify-center text-orange-400 text-sm">👨‍👩‍👧</span>
                  For Parents
                </h3>
                <div className="space-y-4">
                  {howItWorks.parents.map((item) => (
                    <div
                      key={item.step}
                      className="flex gap-4 p-4 rounded-xl bg-white border border-gray-200 dark:bg-gray-800/50 dark:border-gray-700/50"
                    >
                      <div className="w-10 h-10 rounded-full bg-gradient-to-br from-orange-500 to-blue-500 flex items-center justify-center text-white font-bold shrink-0">
                        {item.step}
                      </div>
                      <div>
                        <h4 className="font-semibold text-gray-900 dark:text-white mb-1">{item.title}</h4>
                        <p className="text-gray-600 dark:text-gray-400 text-sm">{item.description}</p>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* Testimonials Section */}
        <section className="py-24 bg-white dark:bg-gray-950">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <SectionHeader
              badge="Testimonials"
              title="Trusted by schools and parents"
              description="See what our users are saying about ApoBasi."
            />

            <div className="grid md:grid-cols-3 gap-6">
              {testimonials.map((testimonial) => (
                <Card key={testimonial.author} variant="glass" className="flex flex-col">
                  <div className="flex-1">
                    <svg className="w-8 h-8 text-blue-500/50 mb-4" fill="currentColor" viewBox="0 0 24 24">
                      <path d="M14.017 21v-7.391c0-5.704 3.731-9.57 8.983-10.609l.995 2.151c-2.432.917-3.995 3.638-3.995 5.849h4v10h-9.983zm-14.017 0v-7.391c0-5.704 3.748-9.57 9-10.609l.996 2.151c-2.433.917-3.996 3.638-3.996 5.849h3.983v10h-9.983z" />
                    </svg>
                    <p className="text-gray-700 dark:text-gray-200 leading-relaxed mb-6">{testimonial.quote}</p>
                  </div>
                  <div className="flex items-center gap-3 pt-4 border-t border-gray-700">
                    <div className="w-10 h-10 rounded-full bg-gradient-to-r from-blue-500 to-blue-600 flex items-center justify-center text-white font-semibold text-sm">
                      {testimonial.avatar}
                    </div>
                    <div>
                      <p className="font-semibold text-gray-900 dark:text-white text-sm">{testimonial.author}</p>
                      <p className="text-gray-500 dark:text-gray-400 text-xs">{testimonial.role}</p>
                    </div>
                  </div>
                </Card>
              ))}
            </div>
          </div>
        </section>

        {/* CTA Section */}
        <section className="py-24 bg-gradient-to-b from-blue-50 to-blue-100 dark:from-gray-900 dark:to-gray-950">
          <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
            <Badge variant="success" className="mb-6">Get Started Today</Badge>
            <h2 className="text-3xl md:text-4xl font-bold text-gray-900 dark:text-white mb-6">
              Ready to transform your school transport?
            </h2>
            <p className="text-gray-700 dark:text-gray-300 text-lg mb-8 max-w-2xl mx-auto">
              Join schools across East Africa who trust ApoBasi to keep their students safe
              and parents informed.
            </p>
            <div className="flex flex-wrap justify-center gap-4">
              <Button variant="primary" size="lg" href="#contact">
                Request a Demo
              </Button>
              <Button variant="outline" size="lg" href="/download">
                Download the App
              </Button>
            </div>
          </div>
        </section>

        {/* Contact Section */}
        <section id="contact" className="py-24 bg-gray-50 dark:bg-gray-900">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div className="grid lg:grid-cols-2 gap-12">
              <div>
                <SectionHeader
                  badge="Contact Us"
                  title="Let's discuss your needs"
                  description="We're currently onboarding pilot schools in East Africa. If you'd like to learn more about ApoBasi or see a live demo, we'd love to hear from you."
                  align="left"
                />

                <div className="space-y-4 mb-8">
                  <div className="flex items-center gap-4 p-4 rounded-xl bg-white border border-gray-200 dark:bg-gray-800/50 dark:border-gray-700/50">
                    <div className="w-10 h-10 rounded-full bg-blue-500/20 flex items-center justify-center text-blue-400">
                      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                      </svg>
                    </div>
                    <div>
                      <p className="text-gray-500 text-sm dark:text-gray-400">Email us at</p>
                      <a href="mailto:hello@apobasi.com" className="text-blue-600 font-medium hover:text-blue-500 dark:text-white dark:hover:text-blue-400 transition-colors">
                        hello@apobasi.com
                      </a>
                    </div>
                  </div>

                  <div className="flex items-center gap-4 p-4 rounded-xl bg-white border border-gray-200 dark:bg-gray-800/50 dark:border-gray-700/50">
                    <div className="w-10 h-10 rounded-full bg-orange-500/20 flex items-center justify-center text-orange-400">
                      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                      </svg>
                    </div>
                    <div>
                      <p className="text-gray-500 text-sm dark:text-gray-400">Serving schools in</p>
                      <p className="text-gray-900 font-medium dark:text-white">Africa</p>
                    </div>
                  </div>
                </div>

                <p className="text-gray-600 text-sm dark:text-gray-500">
                  For school partnerships and pilots, please include your school name, city, and estimated number of students.
                </p>
              </div>

              {/* Contact Form */}
              <Card variant="gradient" className="p-8">
                <form className="space-y-6" action="https://formspree.io/f/your-form-id" method="POST">
                  <div>
                    <label htmlFor="name" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Full Name</label>
                    <input
                      type="text"
                      id="name"
                      name="name"
                      required
                      className="w-full px-4 py-3 rounded-xl bg-white border border-gray-300 text-gray-900 placeholder-gray-400 focus:border-blue-500 focus:ring-1 focus:ring-blue-500 dark:bg-gray-800 dark:border-gray-700 dark:text-white dark:placeholder-gray-500 transition-colors"
                      placeholder="Your name"
                    />
                  </div>

                  <div>
                    <label htmlFor="email" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Email Address</label>
                    <input
                      type="email"
                      id="email"
                      name="email"
                      required
                      className="w-full px-4 py-3 rounded-xl bg-white border border-gray-300 text-gray-900 placeholder-gray-400 focus:border-blue-500 focus:ring-1 focus:ring-blue-500 dark:bg-gray-800 dark:border-gray-700 dark:text-white dark:placeholder-gray-500 transition-colors"
                      placeholder="you@school.edu"
                    />
                  </div>

                  <div>
                    <label htmlFor="school" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">School Name</label>
                    <input
                      type="text"
                      id="school"
                      name="school"
                      className="w-full px-4 py-3 rounded-xl bg-white border border-gray-300 text-gray-900 placeholder-gray-400 focus:border-blue-500 focus:ring-1 focus:ring-blue-500 dark:bg-gray-800 dark:border-gray-700 dark:text-white dark:placeholder-gray-500 transition-colors"
                      placeholder="Your school's name"
                    />
                  </div>

                  <div>
                    <label htmlFor="message" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Message</label>
                    <textarea
                      id="message"
                      name="message"
                      rows={4}
                      required
                      className="w-full px-4 py-3 rounded-xl bg-white border border-gray-300 text-gray-900 placeholder-gray-400 focus:border-blue-500 focus:ring-1 focus:ring-blue-500 dark:bg-gray-800 dark:border-gray-700 dark:text-white dark:placeholder-gray-500 transition-colors resize-none"
                      placeholder="Tell us about your school and transport needs..."
                    ></textarea>
                  </div>

                  <Button variant="primary" size="lg" className="w-full" type="submit">
                    Send Message
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M14 5l7 7m0 0l-7 7m7-7H3" />
                    </svg>
                  </Button>
                </form>
              </Card>
            </div>
          </div>
        </section>
      </main>

      <Footer />
    </div>
  );
}
