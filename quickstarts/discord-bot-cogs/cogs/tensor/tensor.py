import discord
from discord import app_commands
from discord.app_commands import guild_only
from discord.ext import commands


class Tensor(commands.Cog, name="Tensor"):
    def __init__(self, bot: commands.Bot):
        self.bot = bot

    @guild_only()
    @app_commands.command(name="test", description="test")
    async def test(self, interaction: discord.Interaction):
        await interaction.response.defer(ephemeral=True)
        await interaction.followup.send("test")


async def setup(bot: commands.Bot) -> None:
    await bot.add_cog(Tensor(bot))
