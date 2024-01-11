import {Button, Group} from "@mantine/core";
import {NextPageWithLayout} from "./_app";
import {Layout} from "../components/layout/Layout";

const IndexPage: NextPageWithLayout = () => {
    return (
        <Group>
            <Button>Index page</Button>
        </Group>
    );
}

IndexPage.getLayout = function getLayout(page) {
    return (
        <Layout>
            {page}
        </Layout>
    )
}

export default IndexPage;
