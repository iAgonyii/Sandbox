/** @type {import('next').NextConfig} */
const nextConfig = {
    reactStrictMode: false,
    swcMinify: true,
    webpack: (config) => {
        config.externals.push('pino-pretty', 'lokijs', 'encoding');
        return config;
    },
    compiler: {
        removeConsole: process.env.NODE_ENV === 'production',
    },
};

export default nextConfig;
