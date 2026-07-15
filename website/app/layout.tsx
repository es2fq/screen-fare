import type { Metadata } from 'next'
import { Inter, Instrument_Serif } from 'next/font/google'
import './globals.css'

const inter = Inter({
  subsets: ['latin'],
  variable: '--font-inter'
})

const instrumentSerif = Instrument_Serif({
  weight: ['400'],
  style: ['normal', 'italic'],
  subsets: ['latin'],
  variable: '--font-instrument'
})

export const metadata: Metadata = {
  title: 'Screen Fare — Pay the fare to pass',
  description: 'Screen Fare puts a small toll in front of the apps that pull you in. Pay a short, deliberate fare and the app opens — for a set window, then it locks itself again.',
  icons: {
    icon: '/images/icon-120.png',
    apple: '/images/icon-180.png',
  },
  openGraph: {
    title: 'Screen Fare — Pay the fare to pass',
    description: 'A small toll in front of the apps that pull you in. Pay a short, deliberate fare and the app opens — for a window you choose, then it locks itself again.',
  }
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en" className={`${inter.variable} ${instrumentSerif.variable}`}>
      <body>{children}</body>
    </html>
  )
}
