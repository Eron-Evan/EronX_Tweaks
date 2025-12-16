import { defineConfig } from 'vitepress'

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title: "EronX Tweaks",
  lang: "en-US",
  ignoreDeadLinks: true,
  cleanUrls: true,

  sitemap: {
    hostname: 'https://EronX_Tweaks.rem01gaming.dev'
  },

  head: [
    ['link', { rel: "icon", type: "image/png", href: "/favicon.png", sizes: "64x64"}],
    ['link', { rel: "icon", type: "image/png", href: "/android-chrome.png", sizes: "192x192"}],
    ['link', { rel: "apple-touch-icon", type: "image/png", href: "/apple-touch-icon.png", sizes: "180x180"}],
    ['meta', { name: "hostname", content: "EronX_Tweaks.rem01gaming.dev"}],
    ['meta', { name: "expected-hostname", content: "EronX_Tweaks.rem01gaming.dev"}],
    ['meta', { name: "keywords", content: "EronX Tweaks, Tweak, Magisk Module, apk, module, performance module, Gaming, Android, Module magisk, gaming performance" }],
    ['meta', { property: "og:type", content: "website"}],
    ['meta', { property: "og:locale", content: "en-US"}],
    ['meta', { property: "og:site_name", content: "EronX Tweaks"}],
    ['meta', { property: "twitter:card", content: "summary_large_image"}],

    // Google Analytics
    [
      'script',
      { async: '', src: 'https://www.googletagmanager.com/gtag/js?id=G-1962PRCX05' }
    ],
    [
      'script',
      {},
      `window.dataLayer = window.dataLayer || [];
      function gtag(){dataLayer.push(arguments);}
      gtag('js', new Date());
      gtag('config', 'G-1962PRCX05');`
    ]
  ],

  transformPageData(pageData) {
    // Dynamic elements (keep these unless moved to frontmatter)
    const canonicalUrl = `${this.sitemap.hostname}/${pageData.relativePath}`
      .replace(/index\.md$/, '')
      .replace(/\.md$/, '');
    const ogImage = pageData.frontmatter.ogp
      ? `${this.sitemap.hostname}${pageData.frontmatter.ogp}`
      : `${this.sitemap.hostname}/ogp/default.webp`;

    pageData.frontmatter.head ??= [];

    // Add dynamic meta tags
    pageData.frontmatter.head.push(
      ['link', { rel: "canonical", href: canonicalUrl }],
      ['meta', { property: "og:title", content: pageData.frontmatter.layout === 'home' ? pageData.title : `${pageData.title} | EronX Tweaks` }],
      ['meta', { property: "og:url", content: canonicalUrl }],
      ['meta', { property: "og:image", content: ogImage }],
      ['meta', { property: "og:description", content: pageData.description }],
      ['meta', { property: "twitter:image", content: ogImage }],
      ['meta', { property: "twitter:title", content: pageData.frontmatter.layout === 'home' ? pageData.title : `${pageData.title} | EronX Tweaks` }],
      ['meta', { property: "twitter:description", content: pageData.description }]
    );

    // Structured data (homepage only)
    if (pageData.relativePath === 'index.md') {
      pageData.frontmatter.head.push([
        'script',
        { type: "application/ld+json" },
        JSON.stringify({
          "@context": "https://schema.org",
          "@type": "WebSite",
          "name": "EronX Tweaks",
          "alternateName": "EronX Tweak",
          "url": "https://EronX_Tweaks.rem01gaming.dev/"
        })
      ]);
    }
  },

  themeConfig: {
    nav: [
      { text: 'Guide', link: '/guide/what-is-EronX_Tweaks-tweaks' },
      {
        text: 'Donate',
        items: [
          { text: 'Saweria', link: 'https://saweria.co/ERON' },
          { text: 'Sociabuzz', link: 'https://sociabuzz.com/ERON' }
        ]
      },
      { text: 'Download', link: '/download' }
    ],

    sidebar: [
      {
        text: 'Guide',
        items: [
          { text: 'What is EronX Tweaks?', link: '/guide/what-is-EronX_Tweaks-tweaks' },
          { text: 'Module WebUI and Configuration', link: '/guide/webui-and-configuration' },
          { text: 'EronX Tweaks Addon', link: '/guide/addon' },
          { text: 'FAQ', link: '/guide/faq' }
        ]
      },
      {
        text: 'Donate',
        items: [
          { text: 'Saweria', link: 'https://saweria.co/ERON' },
          { text: 'Buymeacoffee', link: 'https://www.buymeacoffee.com/ERON' }
        ]
      },
      { text: 'Download', link: '/download' }
    ],
    
    search: {
        provider: "local",
        options: {
            locales: {
                root: {
                    translations: {
                        button: {
                            buttonText: "Search Documents",
                            buttonAriaLabel: "Search Documents",
                        },
                        modal: {
                            noResultsText: "No results could be found",
                            resetButtonTitle: "Clear the search criteria",
                            footer: {
                                selectText: "option",
                                navigateText: "switchover",
                            },
                        },
                    },
                },
            },
        },
    }, 

    footer: {
      message: 'Released under the Apache License 2.0.',
      copyright: 'Copyright &copy 2024-present ERON'
    },
    
    editLink: {
        pattern: 'https://github.com/ERON/EronX_Tweaks/edit/main/website/docs/:path',
        text: 'Edit this page in GitHub'
    },

    socialLinks: [
      { icon: 'github', link: 'https://github.com/ERON/EronX_Tweaks', ariaLabel: 'GitHub' }
    ]
  }
})
