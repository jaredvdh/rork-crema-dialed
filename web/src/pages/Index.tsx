import { useState } from "react";
import {
  Coffee,
  Mail,
  Shield,
  FileText,
  LifeBuoy,
  ChevronDown,
  Lightbulb,
  Lock,
  Database,
  Star,
  ArrowUpRight,
} from "lucide-react";

const SUPPORT_EMAIL = "support@cremadialed.app";
const APP_NAME = "Crema Dialed";
const LAST_UPDATED = "17 June 2026";

type Faq = { q: string; a: string };

const faqs: Faq[] = [
  {
    q: "How do I add my espresso machine and grinder?",
    a: "Open Settings, tap Equipment, then add a machine or grinder. Browse by brand or search for your exact model. You can keep multiple machines and switch your active setup at any time.",
  },
  {
    q: "Why aren't my measurements showing in grams / ounces?",
    a: "Units are configured under Settings, App Preferences. You can independently set weight, volume and temperature units, and the whole app updates instantly to match.",
  },
  {
    q: "How does dial-in work?",
    a: "The Dial In screen guides you with a golden recipe based on your dose, target yield and shot time. Pull a shot, record the result, and the coach suggests grind and ratio adjustments for your next attempt.",
  },
  {
    q: "Is my data backed up?",
    a: "Your beans, dial-in history, equipment and check-ins are stored on your device. You can export a backup at any time from Settings, Data & Backup, and import it again later or on a new device.",
  },
  {
    q: "How do I track machine maintenance?",
    a: "The Maintenance section lets you log backflushes, descaling, group head cleans, burr cleans and more, with optional weekly, monthly or custom reminders.",
  },
];

function Section({
  id,
  icon,
  title,
  children,
}: {
  id: string;
  icon: React.ReactNode;
  title: string;
  children: React.ReactNode;
}) {
  return (
    <section id={id} className="scroll-mt-24">
      <div className="mb-6 flex items-center gap-3">
        <div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-primary/10 text-primary">
          {icon}
        </div>
        <h2 className="text-2xl font-bold tracking-tight text-foreground">{title}</h2>
      </div>
      {children}
    </section>
  );
}

function FaqItem({ faq }: { faq: Faq }) {
  const [open, setOpen] = useState<boolean>(false);
  return (
    <div className="rounded-2xl border border-border bg-card">
      <button
        type="button"
        onClick={() => setOpen((v) => !v)}
        className="flex w-full items-center justify-between gap-4 px-5 py-4 text-left"
      >
        <span className="font-medium text-foreground">{faq.q}</span>
        <ChevronDown
          className={`h-5 w-5 shrink-0 text-muted-foreground transition-transform duration-300 ${
            open ? "rotate-180" : ""
          }`}
        />
      </button>
      <div
        className={`grid transition-all duration-300 ease-out ${
          open ? "grid-rows-[1fr] opacity-100" : "grid-rows-[0fr] opacity-0"
        }`}
      >
        <div className="overflow-hidden">
          <p className="px-5 pb-5 text-muted-foreground">{faq.a}</p>
        </div>
      </div>
    </div>
  );
}

const Index = () => {
  return (
    <div className="min-h-screen bg-background">
      {/* Header */}
      <header className="sticky top-0 z-40 border-b border-border/60 bg-background/80 backdrop-blur-xl">
        <div className="mx-auto flex max-w-4xl items-center justify-between px-5 py-4">
          <div className="flex items-center gap-2.5">
            <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-primary text-primary-foreground">
              <Coffee className="h-5 w-5" />
            </div>
            <span className="font-bold tracking-tight text-foreground">{APP_NAME}</span>
          </div>
          <nav className="hidden items-center gap-6 text-sm font-medium text-muted-foreground sm:flex">
            <a href="#help" className="transition-colors hover:text-foreground">Help</a>
            <a href="#contact" className="transition-colors hover:text-foreground">Contact</a>
            <a href="#privacy" className="transition-colors hover:text-foreground">Privacy</a>
            <a href="#terms" className="transition-colors hover:text-foreground">Terms</a>
          </nav>
        </div>
      </header>

      {/* Hero */}
      <div className="relative overflow-hidden">
        <div className="pointer-events-none absolute inset-0 bg-gradient-to-b from-primary/10 via-accent/5 to-transparent" />
        <div
          className="pointer-events-none absolute -right-24 -top-24 h-72 w-72 rounded-full opacity-30 blur-3xl"
          style={{ background: "radial-gradient(circle, hsl(30 78% 52%) 0%, transparent 70%)" }}
        />
        <div className="relative mx-auto max-w-4xl px-5 pb-14 pt-16 text-center sm:pt-20">
          <span className="inline-flex items-center gap-2 rounded-full border border-border bg-card px-4 py-1.5 text-sm font-medium text-muted-foreground">
            <LifeBuoy className="h-4 w-4 text-accent" />
            Support Center
          </span>
          <h1 className="mt-6 text-4xl font-extrabold tracking-tight text-foreground sm:text-5xl">
            We're here to help you
            <span className="block text-primary">dial in the perfect shot.</span>
          </h1>
          <p className="mx-auto mt-5 max-w-xl text-lg text-muted-foreground">
            Find answers, get in touch, and read how {APP_NAME} handles your data.
          </p>
          <div className="mt-8 flex flex-wrap items-center justify-center gap-3">
            <a
              href={`mailto:${SUPPORT_EMAIL}`}
              className="inline-flex items-center gap-2 rounded-full bg-primary px-6 py-3 font-semibold text-primary-foreground shadow-sm transition-transform hover:scale-[1.03]"
            >
              <Mail className="h-4 w-4" />
              Contact Support
            </a>
            <a
              href="#help"
              className="inline-flex items-center gap-2 rounded-full border border-border bg-card px-6 py-3 font-semibold text-foreground transition-colors hover:bg-secondary"
            >
              Browse Help
            </a>
          </div>
        </div>
      </div>

      {/* Body */}
      <main className="mx-auto max-w-4xl space-y-20 px-5 py-16">
        {/* Help / FAQ */}
        <Section id="help" icon={<Lightbulb className="h-5 w-5" />} title="Frequently asked questions">
          <div className="space-y-3">
            {faqs.map((faq) => (
              <FaqItem key={faq.q} faq={faq} />
            ))}
          </div>
        </Section>

        {/* Contact */}
        <Section id="contact" icon={<Mail className="h-5 w-5" />} title="Get in touch">
          <div className="grid gap-4 sm:grid-cols-2">
            <a
              href={`mailto:${SUPPORT_EMAIL}`}
              className="group rounded-2xl border border-border bg-card p-6 transition-colors hover:border-primary/40"
            >
              <div className="flex items-center justify-between">
                <h3 className="font-semibold text-foreground">Email Support</h3>
                <ArrowUpRight className="h-5 w-5 text-muted-foreground transition-transform group-hover:translate-x-0.5 group-hover:-translate-y-0.5" />
              </div>
              <p className="mt-2 text-sm text-muted-foreground">
                Questions, bugs or account help. We typically reply within 1–2 business days.
              </p>
              <p className="mt-4 font-medium text-primary">{SUPPORT_EMAIL}</p>
            </a>
            <a
              href={`mailto:${SUPPORT_EMAIL}?subject=Feature%20Request%20%E2%80%94%20${encodeURIComponent(APP_NAME)}`}
              className="group rounded-2xl border border-border bg-card p-6 transition-colors hover:border-primary/40"
            >
              <div className="flex items-center justify-between">
                <h3 className="font-semibold text-foreground">Feature Requests</h3>
                <Star className="h-5 w-5 text-accent" />
              </div>
              <p className="mt-2 text-sm text-muted-foreground">
                Got an idea to make {APP_NAME} better? We'd love to hear what you'd brew next.
              </p>
              <p className="mt-4 font-medium text-primary">Send us your idea</p>
            </a>
          </div>
        </Section>

        {/* Privacy Policy */}
        <Section id="privacy" icon={<Shield className="h-5 w-5" />} title="Privacy Policy">
          <p className="mb-6 text-sm text-muted-foreground">Last updated: {LAST_UPDATED}</p>
          <div className="space-y-6 rounded-2xl border border-border bg-card p-6 sm:p-8">
            <p className="text-muted-foreground">
              {APP_NAME} ("we", "us", "the app") is designed with your privacy in mind. This policy
              explains what information the app handles and how. By using {APP_NAME}, you agree to
              this policy.
            </p>

            <div>
              <h3 className="flex items-center gap-2 font-semibold text-foreground">
                <Database className="h-4 w-4 text-primary" /> Information we store
              </h3>
              <p className="mt-2 text-muted-foreground">
                {APP_NAME} stores the data you create — such as beans, dial-in history, equipment,
                maintenance logs, café check-ins and your preferences — locally on your device. This
                data stays on your device unless you choose to export or back it up yourself.
              </p>
            </div>

            <div>
              <h3 className="flex items-center gap-2 font-semibold text-foreground">
                <Lock className="h-4 w-4 text-primary" /> We do not track you
              </h3>
              <p className="mt-2 text-muted-foreground">
                We do not collect personal information for advertising, and we do not track you
                across other apps or websites. {APP_NAME} contains no third-party advertising
                trackers.
              </p>
            </div>

            <div>
              <h3 className="font-semibold text-foreground">Location services</h3>
              <p className="mt-2 text-muted-foreground">
                If you enable location services, your location is used only on-device to find nearby
                cafés and power Coffee Passport check-ins. You can turn this off at any time in the
                app's settings or in your device settings. Location data is not sold or shared.
              </p>
            </div>

            <div>
              <h3 className="font-semibold text-foreground">Backups and exports</h3>
              <p className="mt-2 text-muted-foreground">
                When you create a backup or export your data, the resulting file is handled by you
                through your device and the storage or sharing destinations you choose. We do not
                receive a copy of your exported data.
              </p>
            </div>

            <div>
              <h3 className="font-semibold text-foreground">Children's privacy</h3>
              <p className="mt-2 text-muted-foreground">
                {APP_NAME} is not directed to children under 13 and we do not knowingly collect
                personal information from children.
              </p>
            </div>

            <div>
              <h3 className="font-semibold text-foreground">Changes to this policy</h3>
              <p className="mt-2 text-muted-foreground">
                We may update this policy from time to time. Material changes will be reflected by
                the "last updated" date above.
              </p>
            </div>

            <div>
              <h3 className="font-semibold text-foreground">Contact</h3>
              <p className="mt-2 text-muted-foreground">
                Questions about privacy? Email us at{" "}
                <a href={`mailto:${SUPPORT_EMAIL}`} className="font-medium text-primary underline-offset-2 hover:underline">
                  {SUPPORT_EMAIL}
                </a>
                .
              </p>
            </div>
          </div>
        </Section>

        {/* Terms */}
        <Section id="terms" icon={<FileText className="h-5 w-5" />} title="Terms of Service">
          <div className="space-y-6 rounded-2xl border border-border bg-card p-6 sm:p-8">
            <p className="text-muted-foreground">
              By downloading or using {APP_NAME}, you agree to these terms. The app is provided to
              help you track and improve your espresso brewing.
            </p>
            <div>
              <h3 className="font-semibold text-foreground">Use of the app</h3>
              <p className="mt-2 text-muted-foreground">
                You may use {APP_NAME} for your personal, non-commercial coffee journey. You agree
                not to misuse the app or attempt to disrupt its functionality.
              </p>
            </div>
            <div>
              <h3 className="font-semibold text-foreground">Your data and responsibility</h3>
              <p className="mt-2 text-muted-foreground">
                Your records are stored on your device. You are responsible for backing up your data.
                Recipes and dial-in suggestions are guidance only — results vary with equipment,
                beans and technique.
              </p>
            </div>
            <div>
              <h3 className="font-semibold text-foreground">Disclaimer</h3>
              <p className="mt-2 text-muted-foreground">
                The app is provided "as is" without warranties of any kind. To the maximum extent
                permitted by law, we are not liable for any damages arising from your use of the app.
              </p>
            </div>
            <div>
              <h3 className="font-semibold text-foreground">Contact</h3>
              <p className="mt-2 text-muted-foreground">
                Questions about these terms? Email{" "}
                <a href={`mailto:${SUPPORT_EMAIL}`} className="font-medium text-primary underline-offset-2 hover:underline">
                  {SUPPORT_EMAIL}
                </a>
                .
              </p>
            </div>
          </div>
        </Section>
      </main>

      {/* Footer */}
      <footer className="border-t border-border/60">
        <div className="mx-auto flex max-w-4xl flex-col items-center justify-between gap-4 px-5 py-8 text-sm text-muted-foreground sm:flex-row">
          <div className="flex items-center gap-2">
            <Coffee className="h-4 w-4 text-primary" />
            <span>© {new Date().getFullYear()} {APP_NAME}. All rights reserved.</span>
          </div>
          <div className="flex items-center gap-5">
            <a href="#privacy" className="transition-colors hover:text-foreground">Privacy</a>
            <a href="#terms" className="transition-colors hover:text-foreground">Terms</a>
            <a href={`mailto:${SUPPORT_EMAIL}`} className="transition-colors hover:text-foreground">Contact</a>
          </div>
        </div>
      </footer>
    </div>
  );
};

export default Index;
