# Screen Fare Website

The marketing website for Screen Fare, built with Next.js 15 and deployed to Vercel.

## 🚀 Quick Start

### Local Development

```bash
# Install dependencies
npm install

# Run development server
npm run dev
```

Visit [http://localhost:3000](http://localhost:3000) to see the site locally.

### Build for Production

```bash
# Create production build
npm run build

# Preview production build locally
npm start
```

## 📦 What's Inside

```
website/
├── app/
│   ├── layout.tsx          # Root layout with fonts & metadata
│   ├── page.tsx            # Landing page (/)
│   ├── globals.css         # Global styles
│   ├── terms/
│   │   ├── page.tsx        # Terms of Use (/terms)
│   │   └── legal.css       # Legal pages styles
│   └── privacy/
│       └── page.tsx        # Privacy Policy (/privacy)
├── public/
│   └── images/             # All website images
│       ├── icon-*.png      # App icons
│       ├── fare-*.png      # Challenge screenshots
│       ├── locked-apps.png # Shield screen
│       ├── today.png       # Today tab screen
│       └── blocks.png      # Blocks tab screen
├── package.json
├── next.config.js          # Next.js config (static export)
└── tsconfig.json
```

## 🌐 Deploying to Vercel

### Step 1: Push to GitHub

Make sure your website folder is committed to your repo:

```bash
cd /Users/esong/coding/screen-fare
git add website/
git commit -m "Add website"
git push origin main
```

### Step 2: Connect to Vercel

1. Go to [vercel.com](https://vercel.com) and sign up/login
2. Click **"Add New Project"**
3. Import your `screen-fare` repository
4. Configure the project:
   - **Framework Preset:** Next.js
   - **Root Directory:** `website` ⚠️ IMPORTANT
   - **Build Command:** `npm run build` (should be auto-detected)
   - **Output Directory:** `out` (should be auto-detected)
5. Click **"Deploy"**

### Step 3: Add Custom Domain

Once deployed:

1. Go to your project's **Settings → Domains**
2. Add `screenfare.app`
3. Follow Vercel's instructions to update your domain's DNS:
   - Add an **A record** pointing to Vercel's IP (shown in dashboard)
   - Add a **CNAME** for `www` pointing to your Vercel project
4. Wait for DNS propagation (can take up to 48 hours, usually ~10 minutes)

Your site will be live at `https://screenfare.app` 🎉

## 🎨 Design System

The website matches your app's design system:

### Colors
- **Cream Background:** `#EFEBE3`
- **Ink (Text):** `#1A1A1A`
- **Muted:** `#6E6963`, `#8B8680`
- **Terra (Accent):** `oklch(0.585 0.125 40)` (terracotta orange)
- **Card Background:** `#FBF9F5`

### Typography
- **Headings:** Instrument Serif (Google Fonts)
- **Body:** Inter (Google Fonts)

## 🔧 Configuration

### Update Content

- **Landing page copy:** `app/page.tsx`
- **Terms & Privacy:** Update company name/jurisdiction in `app/terms/page.tsx` and `app/privacy/page.tsx`
- **Meta tags:** Update in `app/layout.tsx`

### Add Images

Place new images in `public/images/` and reference them as `/images/filename.png` in your code.

### Styling

- Global styles: `app/globals.css`
- Legal pages: `app/terms/legal.css`
- Uses CSS custom properties from the global stylesheet

## 📝 To-Do After Deployment

- [ ] Update `[DEVELOPER / COMPANY NAME]` in Terms & Privacy pages
- [ ] Update `[JURISDICTION]` in Terms page
- [ ] Update "Coming soon" badge to real App Store link when published
- [ ] Add actual App Store link in footer and CTA sections
- [ ] Consider adding a favicon.ico (use icon-120.png converted)

## 🆘 Troubleshooting

**"Module not found" errors:**
```bash
rm -rf node_modules package-lock.json
npm install
```

**Vercel deployment fails:**
- Check that Root Directory is set to `website`
- Verify `next.config.js` has `output: 'export'`

**Images not loading:**
- Ensure images are in `public/images/`
- Use `/images/name.png` (with leading slash) in code

**Fonts not loading:**
- Fonts are loaded from Google Fonts CDN automatically
- Check `app/layout.tsx` for font configuration

## 📚 Learn More

- [Next.js Documentation](https://nextjs.org/docs)
- [Vercel Documentation](https://vercel.com/docs)
- [Next.js Static Exports](https://nextjs.org/docs/app/building-your-application/deploying/static-exports)

---

© 2026 Screen Fare
