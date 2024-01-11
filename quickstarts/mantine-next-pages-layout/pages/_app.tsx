import "@mantine/core/styles.css";
import Head from "next/head";
import {MantineProvider} from "@mantine/core";
import {theme} from "../theme";
import {ReactElement, ReactNode} from "react";
import {AppProps} from "next/app";
import {NextPage} from "next";

export type NextPageWithLayout<P = {}, IP = P> = NextPage<P, IP> & {
    getLayout?: (page: ReactElement) => ReactNode
}

type AppPropsWithLayout = AppProps & {
    Component: NextPageWithLayout
}

export default function App({Component, pageProps}: AppPropsWithLayout) {
    const getLayout = Component.getLayout ?? ((page) => page);

    return (
        <MantineProvider theme={theme} defaultColorScheme={"dark"}>
            <Head>
                <title>Mantine Template</title>
                <meta
                    name="viewport"
                    content="minimum-scale=1, initial-scale=1, width=device-width, user-scalable=no"
                />
                <link rel="shortcut icon" href="/favicon.svg"/>
            </Head>
            {getLayout(<Component {...pageProps} />)}
        </MantineProvider>
    );
}
