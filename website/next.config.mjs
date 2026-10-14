import nextra from 'nextra'

const withNextra = nextra({
  // theme is provided via theme.config.tsx
  theme: 'nextra-theme-docs',
  themeConfig: './theme.config.tsx',
  defaultShowCopyCode: true
})

export default withNextra({
  output: 'export',
  images: { unoptimized: true },
  basePath: '/zero-adaptive-link',
  assetPrefix: '/zero-adaptive-link',
  trailingSlash: true,
  reactStrictMode: true
})
