'use client'

import Link from 'next/link'
import { useEffect } from 'react'

export default function Home() {
  useEffect(() => {
    // Phone mockup setup
    const SF_FARES = {
      math: '/images/fare-math.png',
      typing: '/images/fare-typing.png',
      memory: '/images/fare-memory.png',
      breath: '/images/fare-breath.png',
      trivia: '/images/fare-trivia.png',
      walk: '/images/fare-walk.png'
    }

    const SF_SCREENS: Record<string, [string, string]> = {
      shield: ['/images/locked-apps.png', 'The Screen Fare gate: a single-fare ticket in front of a blocked app'],
      today: ['/images/today.png', 'The Today tab: an unlocked app counting down, with screen time below'],
      blocks: ['/images/blocks.png', 'The Blocks tab: blocked apps and scheduled hours'],
    }

    document.querySelectorAll('.phone-slot').forEach(el => {
      const kind = el.getAttribute('data-phone')
      const scale = parseFloat(el.getAttribute('data-scale') || '1')
      const w = (402 + 18) * scale
      const h = (874 + 18) * scale

      if (!kind) return

      const inner = kind === 'ticket'
        ? '<div class="fare-stack">' + Object.entries(SF_FARES).map(([k, s], i) =>
            `<img data-fk="${k}" src="${s}" alt="The ${k} fare ticket" loading="lazy"${i === 0 ? ' class="on"' : ''} />`
          ).join('') + '</div>'
        : `<img class="scr" src="${SF_SCREENS[kind][0]}" alt="${SF_SCREENS[kind][1]}"${kind === 'shield' ? '' : ' loading="lazy"'} />`

      el.innerHTML = `<div style="width:${w}px;height:${h}px"><div class="phone-scale" style="transform:scale(${scale})"><div class="bezel">${inner}</div></div></div>`
    })

    // Interactive fare list
    document.querySelectorAll('.fare-list li[data-fare]').forEach(li => {
      const go = () => {
        document.querySelectorAll('.fare-list li[data-fare]').forEach(x =>
          x.classList.toggle('on', x === li)
        )
        document.querySelectorAll('.fare-stack img').forEach(img =>
          img.classList.toggle('on', img.getAttribute('data-fk') === li.getAttribute('data-fare'))
        )
      }
      li.addEventListener('mouseenter', go)
      li.addEventListener('click', go)
    })
  }, [])

  return (
    <>
      <nav>
        <div className="wrap nav-inner">
          <Link className="brand" href="#top">
            <img src="/images/icon-120.png" alt="Screen Fare icon" width={30} height={30} />
            <span>Screen Fare</span>
          </Link>
          <div className="nav-links">
            <Link href="#how">How it works</Link>
            <Link href="#features">Features</Link>
            <Link href="#pricing">Pricing</Link>
            <Link href="#faq">FAQ</Link>
          </div>
          <span className="chip">
            <span className="dot"></span>Coming soon
          </span>
        </div>
      </nav>

      <header className="hero" id="top">
        <div className="wrap hero-grid">
          <div>
            <p className="kicker">Screen Fare for iPhone</p>
            <h1>
              Pay the fare<br />
              to <i>pass.</i>
            </h1>
            <p className="sub">
              A gate in front of the apps that pull you in. Pay one short, deliberate fare and the app opens — for a window you choose, then it locks itself again. Every open becomes a choice, never a reflex.
            </p>
            <div className="hero-ctas">
              <a className="badge soon" href="#" aria-label="Coming soon on the App Store">
                <svg width="24" height="28" viewBox="0 0 24 28" fill="#fff">
                  <path d="M19.6 14.8c0-3 2.5-4.5 2.6-4.6-1.4-2.1-3.6-2.4-4.4-2.4-1.9-.2-3.6 1.1-4.6 1.1-.9 0-2.4-1.1-4-1-2 0-3.9 1.2-5 3-2.1 3.7-.5 9.2 1.5 12.2 1 1.5 2.2 3.1 3.8 3 1.5-.1 2.1-1 4-1s2.4 1 4 1c1.7 0 2.7-1.5 3.7-3 1.2-1.7 1.6-3.4 1.7-3.5-.1 0-3.2-1.2-3.3-4.8zM16.6 5.7c.8-1 1.4-2.4 1.2-3.7-1.2 0-2.7.8-3.5 1.8-.8.9-1.5 2.3-1.3 3.6 1.4.1 2.8-.7 3.6-1.7z"/>
                </svg>
                <span>
                  <span className="b1">COMING SOON ON THE</span>
                  <span className="b2">App Store</span>
                </span>
              </a>
              <span className="hero-note">Free to try · iOS 17 or later</span>
            </div>
          </div>
          <div className="hero-phone">
            <div className="phone-slot" data-phone="shield" data-scale="0.62"></div>
          </div>
        </div>
      </header>

      <section className="steps" id="how">
        <div className="wrap">
          <div className="steps-head">
            <p className="kicker">How it works</p>
            <h2>A toll booth for your attention.</h2>
            <p className="sub">
              Not a wall — a fare. Enough friction to interrupt the reflex, never enough to lock you out of your own phone.
            </p>
          </div>
          <div className="step-grid">
            <div className="step">
              <div className="num">01</div>
              <h3>Choose your apps</h3>
              <p>Choose the apps that distract you the most.</p>
            </div>
            <div className="step">
              <div className="num">02</div>
              <h3>Meet the gate</h3>
              <p>Open a blocked app to arrive at the gate. Walk away to maintain your focus, or pay the fare to unlock.</p>
            </div>
            <div className="step">
              <div className="num">03</div>
              <h3>Pay the fare</h3>
              <p>Clear the fare and you board: the app opens for the window you choose — five minutes, fifteen, an hour. Then it quietly locks itself again.</p>
            </div>
          </div>
        </div>
      </section>

      <section className="terra-band">
        <div className="wrap terra-grid">
          <div className="terra-phone" style={{ display: 'flex', justifyContent: 'center' }}>
            <div className="phone-slot" data-phone="ticket" data-scale="0.56"></div>
          </div>
          <div>
            <p className="kicker">The fare</p>
            <h2>
              A small challenge<br />
              to sharpen the <i>mind.</i>
            </h2>
            <p className="sub">
              Most fares take under a minute — long enough for the reflex to fade and the choice to become yours. Pick the kind of friction that fits the moment — hover or tap one to preview it.
            </p>
            <ul className="fare-list">
              <li data-fare="math" className="on">
                <span className="fdot"></span>Math problem
              </li>
              <li data-fare="typing">
                <span className="fdot"></span>Typing challenge <span className="pro">PRO</span>
              </li>
              <li data-fare="memory">
                <span className="fdot"></span>Memory challenge <span className="pro">PRO</span>
              </li>
              <li data-fare="breath">
                <span className="fdot"></span>Breathing exercise <span className="pro">PRO</span>
              </li>
              <li data-fare="trivia">
                <span className="fdot"></span>Trivia <span className="pro">PRO</span>
              </li>
              <li data-fare="walk">
                <span className="fdot"></span>Take a walk <span className="pro">PRO</span>
              </li>
            </ul>
            <p className="fare-note">
              <span className="fdot"></span>New fares on the way — all included in Pro.
            </p>
          </div>
        </div>
      </section>

      <section className="features" id="features">
        <div className="wrap">
          <div className="feat-row">
            <div className="copy">
              <p className="kicker">Today</p>
              <h2>
                Always know<br />
                what's <i>open.</i>
              </h2>
              <p className="sub">
                One calm view of everything unlocked right now — a live countdown on each app, your screen time alongside. When a window runs out, the gate returns. No nagging, no streaks, no guilt.
              </p>
            </div>
            <div className="phone-wrap">
              <div className="phone-slot" data-phone="today" data-scale="0.56"></div>
            </div>
          </div>
          <div className="feat-row flip">
            <div className="copy">
              <p className="kicker">Blocks</p>
              <h2>
                Gate what<br />
                pulls you in.
              </h2>
              <p className="sub">
                Add a single app or a whole category in a couple of taps. Your blocklist is yours alone.
              </p>
            </div>
            <div className="phone-wrap">
              <div className="phone-slot" data-phone="blocks" data-scale="0.56"></div>
            </div>
          </div>
          <div className="minis">
            <div className="mini">
              <span className="mk">01</span>
              <h3>Custom schedules</h3>
              <p>Choose the hours and days your gates stand — work mornings, school nights, Sundays.</p>
            </div>
            <div className="mini">
              <span className="mk">02</span>
              <h3>Strict Mode</h3>
              <p>A fare in front of the off-switch, the blocklist, and the schedule — so a weak moment costs more than a tap.</p>
            </div>
            <div className="mini">
              <span className="mk">03</span>
              <h3>On by default</h3>
              <p>Runs quietly in the background. Nothing to babysit, nothing to remember to turn on.</p>
            </div>
            <div className="mini">
              <span className="mk">04</span>
              <h3>No accounts</h3>
              <p>No sign-up, no email, no cloud. Delete the app and every trace goes with it.</p>
            </div>
          </div>
        </div>
      </section>

      <section className="privacy">
        <div className="wrap">
          <p className="kicker">Private by design</p>
          <h2>Your habits stay on your phone.</h2>
          <p className="sub">
            Screen Fare works through Apple's Screen Time framework, which means your app activity is handled by iOS itself — on-device, end to end. We run no servers, keep no accounts, and collect no analytics.
          </p>
        </div>
      </section>

      <section className="pricing" id="pricing">
        <div className="wrap">
          <div className="pricing-head">
            <p className="kicker">Pricing</p>
            <h2>Honest, like the fare.</h2>
            <p className="sub">
              Math keeps you honest for free. Pro unlocks every fare and lets you set exactly when apps go quiet — starting with a 7-day free trial.
            </p>
          </div>
          <div className="plan-grid">
            <div className="plan">
              <p className="pname">Free</p>
              <p className="price">$0</p>
              <p className="pnote">Forever</p>
              <ul>
                <li>Unlimited blocked apps &amp; categories</li>
                <li>The math fare, five difficulties</li>
                <li>Today view with live countdowns</li>
                <li>All-day blocking, every day</li>
              </ul>
            </div>
            <div className="plan pro">
              <span className="save">Save 33% yearly</span>
              <p className="pname">Pro</p>
              <p className="price">
                $39.99 <span>/ year</span>
              </p>
              <p className="pnote">or $4.99 / month · 7-day free trial, cancel anytime</p>
              <ul>
                <li>Every fare — typing, memory, breathing, trivia, walking</li>
                <li>Custom schedules — the hours and days apps go quiet</li>
                <li>Strict Mode</li>
                <li>New fares as they ship, included</li>
              </ul>
            </div>
          </div>
        </div>
      </section>

      <section className="faq" id="faq">
        <div className="wrap">
          <h2>Questions, answered.</h2>
          <div className="faq-list">
            <details>
              <summary>Can I just skip the fare?</summary>
              <p>No — that's the point. The gate stands until the fare is paid, though you can always tap Not now and walk away. Screen Fare counts that as a win. And for days you don't trust future-you, Strict Mode puts a fare in front of turning the whole thing off.</p>
            </details>
            <details>
              <summary>Does Screen Fare see what I do on my phone?</summary>
              <p>No. Blocking happens through Apple's Screen Time framework, entirely on your device. Your app list, usage, and schedules never leave your phone, and we have no servers for them to reach anyway.</p>
            </details>
            <details>
              <summary>What happens when the unlock window ends?</summary>
              <p>The app locks itself again, quietly. Next time you open it, the gate is back and a new fare is due. You'll see everything that's currently open — with countdowns — in the Today view.</p>
            </details>
            <details>
              <summary>Do I need an account?</summary>
              <p>No accounts, ever. Download it, pick your apps, done. Purchases are handled by the App Store.</p>
            </details>
            <details>
              <summary>When can I get it?</summary>
              <p>Screen Fare is in final review and coming soon to the App Store for iPhone (iOS 17+). Check back here — this page will carry the download link the moment it's live.</p>
            </details>
          </div>
        </div>
      </section>

      <section className="cta">
        <div className="wrap">
          <h2>
            The tax on <i>distraction.</i>
          </h2>
          <p className="sub">Screen Fare is coming soon to the App Store. Free to try, no account required.</p>
          <a className="badge" href="#" aria-label="Coming soon on the App Store">
            <svg width="24" height="28" viewBox="0 0 24 28" fill="#fff">
              <path d="M19.6 14.8c0-3 2.5-4.5 2.6-4.6-1.4-2.1-3.6-2.4-4.4-2.4-1.9-.2-3.6 1.1-4.6 1.1-.9 0-2.4-1.1-4-1-2 0-3.9 1.2-5 3-2.1 3.7-.5 9.2 1.5 12.2 1 1.5 2.2 3.1 3.8 3 1.5-.1 2.1-1 4-1s2.4 1 4 1c1.7 0 2.7-1.5 3.7-3 1.2-1.7 1.6-3.4 1.7-3.5-.1 0-3.2-1.2-3.3-4.8zM16.6 5.7c.8-1 1.4-2.4 1.2-3.7-1.2 0-2.7.8-3.5 1.8-.8.9-1.5 2.3-1.3 3.6 1.4.1 2.8-.7 3.6-1.7z"/>
            </svg>
            <span>
              <span className="b1">COMING SOON ON THE</span>
              <span className="b2">App Store</span>
            </span>
          </a>
          <span className="hero-note">Free to try · Pro from $39.99/yr</span>
        </div>
      </section>

      <footer>
        <div className="wrap">
          <div className="foot-grid">
            <div className="foot-brand">
              <img src="/images/icon-120.png" alt="" width={26} height={26} />
              <span>Screen Fare</span>
            </div>
            <div className="foot-links">
              <Link href="#how">How it works</Link>
              <Link href="#pricing">Pricing</Link>
              <Link href="#faq">FAQ</Link>
              <Link href="mailto:support@screenfare.app">Support</Link>
              <Link href="/terms">Terms of Use</Link>
              <Link href="/privacy">Privacy Policy</Link>
            </div>
          </div>
          <div className="foot-legal">
            <span>© 2026 Screen Fare. All rights reserved.</span>
            <span>Apple, the Apple logo, and App Store are trademarks of Apple Inc.</span>
          </div>
        </div>
      </footer>
    </>
  )
}
