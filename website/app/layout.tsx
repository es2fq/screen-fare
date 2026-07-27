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
  metadataBase: new URL('https://screenfare.app'),
  title: 'Screen Fare — Pay the fare to pass',
  description: 'Screen Fare puts a small toll in front of the apps that pull you in. Pay a short, deliberate fare and the app opens — for a set window, then it locks itself again.',
  keywords: ['screen time', 'app blocker', 'digital wellbeing', 'focus', 'productivity', 'iPhone', 'iOS', 'mindful phone use', 'distraction blocker'],
  authors: [{ name: 'Screen Fare' }],
  creator: 'Screen Fare',
  publisher: 'Screen Fare',
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
    },
  },
  icons: {
    icon: '/images/icon-120.png',
    apple: '/images/icon-180.png',
  },
  openGraph: {
    type: 'website',
    locale: 'en_US',
    url: 'https://screenfare.app',
    siteName: 'Screen Fare',
    title: 'Screen Fare — Pay the fare to pass',
    description: 'A small toll in front of the apps that pull you in. Pay a short, deliberate fare and the app opens — for a window you choose, then it locks itself again.',
    images: [
      {
        url: '/images/icon-180.png',
        width: 180,
        height: 180,
        alt: 'Screen Fare App Icon',
      },
    ],
  },
  twitter: {
    card: 'summary',
    title: 'Screen Fare — Pay the fare to pass',
    description: 'A small toll in front of the apps that pull you in. Pay a short, deliberate fare and the app opens — for a window you choose, then it locks itself again.',
    images: ['/images/icon-180.png'],
  },
  alternates: {
    canonical: 'https://screenfare.app',
  },
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
