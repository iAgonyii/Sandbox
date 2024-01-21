import os

import discord
from discord.ext import commands
from dotenv import load_dotenv

load_dotenv()
TOKEN = os.getenv('DISCORD_BOT_TOKEN')


class Bot(commands.Bot):
    def __init__(self):
        intents = discord.Intents.default()
        intents.message_content = True
        intents.members = True
        super().__init__(command_prefix=commands.when_mentioned_or('>'), intents=intents)
        self.cogslist = ['cogs.tensor.tensor']

    async def setup_hook(self) -> None:
        for cog in self.cogslist:
            await self.load_extension(cog)

    async def on_ready(self):
        print(f'We have logged in as {bot.user}')
        synced = await self.tree.sync()
        print(f'Synced {str(len(synced))} commands')


bot = Bot()

bot.run(TOKEN)
