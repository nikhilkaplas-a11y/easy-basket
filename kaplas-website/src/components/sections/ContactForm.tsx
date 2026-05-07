"use client";

import { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Send, CheckCircle2, AlertCircle } from "lucide-react";
import { Button } from "@/components/ui/Button";
import { site } from "@/lib/site";

export function ContactForm() {
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [topic, setTopic] = useState("project");
  const [message, setMessage] = useState("");
  const [status, setStatus] = useState<"idle" | "sent" | "error">("idle");

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!name.trim() || !email.trim() || !message.trim()) {
      setStatus("error");
      return;
    }

    const subject = encodeURIComponent(
      `[${topic === "project" ? "Project" : topic === "training" ? "Training" : "General"}] ${name}`
    );
    const body = encodeURIComponent(
      `Name: ${name}\nEmail: ${email}\nTopic: ${topic}\n\n${message}`
    );
    window.location.href = `mailto:${site.email}?subject=${subject}&body=${body}`;
    setStatus("sent");
  }

  return (
    <form
      onSubmit={handleSubmit}
      className="relative overflow-hidden rounded-2xl border border-white/10 bg-gradient-to-br from-white/[0.04] to-transparent p-7 md:p-10"
    >
      <div
        aria-hidden
        className="pointer-events-none absolute -right-20 -top-20 h-64 w-64 rounded-full bg-[#4F46E5]/15 blur-[100px]"
      />
      <div className="relative space-y-5">
        <div className="grid gap-5 md:grid-cols-2">
          <Field
            label="Your name"
            placeholder="Jane Doe"
            value={name}
            onChange={setName}
          />
          <Field
            label="Email address"
            type="email"
            placeholder="jane@company.com"
            value={email}
            onChange={setEmail}
          />
        </div>

        <div>
          <label className="text-xs font-semibold uppercase tracking-[0.18em] text-[#8B91A1]">
            What&apos;s this about?
          </label>
          <div className="mt-3 grid gap-2 sm:grid-cols-3">
            {[
              { v: "project", l: "Start a project" },
              { v: "training", l: "Internship / Training" },
              { v: "other", l: "Something else" },
            ].map((opt) => (
              <button
                key={opt.v}
                type="button"
                onClick={() => setTopic(opt.v)}
                className={`rounded-lg border px-4 py-2.5 text-sm font-medium transition-all ${
                  topic === opt.v
                    ? "border-[#4F46E5]/40 bg-[#4F46E5]/10 text-white"
                    : "border-white/10 bg-white/[0.02] text-[#8B91A1] hover:border-white/20 hover:text-white"
                }`}
              >
                {opt.l}
              </button>
            ))}
          </div>
        </div>

        <div>
          <label className="text-xs font-semibold uppercase tracking-[0.18em] text-[#8B91A1]">
            Tell us more
          </label>
          <textarea
            rows={5}
            value={message}
            onChange={(e) => setMessage(e.target.value)}
            placeholder="A few sentences about what you're building, your timeline, or what you'd like to learn..."
            className="mt-3 w-full resize-none rounded-lg border border-white/10 bg-white/[0.02] px-4 py-3 text-sm text-white placeholder:text-[#5C6275] outline-none transition-all focus:border-[#4F46E5]/40 focus:bg-[#4F46E5]/[0.04]"
          />
        </div>

        <div className="flex flex-col items-start justify-between gap-4 pt-2 sm:flex-row sm:items-center">
          <p className="text-xs text-[#5C6275]">
            We&apos;ll respond within 24 hours.
          </p>
          <Button type="submit" size="md">
            <Send className="h-4 w-4" />
            Send message
          </Button>
        </div>

        <AnimatePresence>
          {status === "sent" && (
            <motion.div
              initial={{ opacity: 0, y: 8 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0 }}
              className="flex items-center gap-2 rounded-lg border border-emerald-500/30 bg-emerald-500/10 px-4 py-3 text-sm text-emerald-300"
            >
              <CheckCircle2 className="h-4 w-4" />
              Opening your email client — finish sending from there.
            </motion.div>
          )}
          {status === "error" && (
            <motion.div
              initial={{ opacity: 0, y: 8 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0 }}
              className="flex items-center gap-2 rounded-lg border border-amber-500/30 bg-amber-500/10 px-4 py-3 text-sm text-amber-300"
            >
              <AlertCircle className="h-4 w-4" />
              Please fill in all required fields.
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </form>
  );
}

function Field({
  label,
  type = "text",
  placeholder,
  value,
  onChange,
}: {
  label: string;
  type?: string;
  placeholder?: string;
  value: string;
  onChange: (v: string) => void;
}) {
  return (
    <div>
      <label className="text-xs font-semibold uppercase tracking-[0.18em] text-[#8B91A1]">
        {label}
      </label>
      <input
        type={type}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        className="mt-3 w-full rounded-lg border border-white/10 bg-white/[0.02] px-4 py-3 text-sm text-white placeholder:text-[#5C6275] outline-none transition-all focus:border-[#4F46E5]/40 focus:bg-[#4F46E5]/[0.04]"
      />
    </div>
  );
}
