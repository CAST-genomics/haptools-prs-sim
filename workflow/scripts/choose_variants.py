#!/usr/bin/env python

import sys
import click
import pandas as pd
from pathlib import Path


@click.command()
@click.argument("frequencies", type=click.Path(exists=True, path_type=Path))
@click.option(
    "-s",
    "--seed",
    type=int,
    default=None,
    show_default="random",
    help="Random seed to use",
)
def main(
    frequencies: Path,
    seed: int = None,
):
	pass


if __name__ == "__main__":
    main()
