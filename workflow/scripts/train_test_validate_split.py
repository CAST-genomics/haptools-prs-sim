#!/usr/bin/env python

import sys
import click
import numpy as np
import pandas as pd
from pathlib import Path


def check_fractions(ctx, param, value):
    if isinstance(value, tuple) and sum(value) == 100:
        return value
    else:
        raise click.BadParameter(
            "Please pass three values that sum to 100"
        )


@click.command()
@click.argument("sample_info", type=click.Path(exists=True, path_type=Path))
@click.argument("train", type=click.Path(path_type=Path))
@click.argument("test", type=click.Path(path_type=Path))
@click.argument("validate", type=click.Path(path_type=Path))
@click.option(
    "-s",
    "--seed",
    type=int,
    default=None,
    show_default="random",
    help="Random seed to use",
)
@click.option(
    "-f",
    "--fractions",
    nargs=3,
    default=[80, 10, 10],
    show_default=True,
    callback=check_fractions,
    type=click.IntRange(0, 100),
    help="The fractions used for the train/test/validate split",
)
def main(
    sample_info: Path,
    train: Path,
    test: Path,
    validate: Path,
    seed: int = None,
    fractions: list[int] = (80, 10, 10),
):
    samples = pd.read_csv(sample_info, sep="\t", header=None, names=["sample", "pop"])
    train_df, test_df, validate_df = [], [], []
    for pop in pd.unique(samples['pop']):
        df = samples[samples['pop'] == pop]
        indices = (np.cumsum(np.array(fractions)/100)[:-1] * len(df)).astype(np.uint32)
        split = np.split(df.sample(frac=1, random_state=seed), indices)
        train_df.append(split[0])
        test_df.append(split[1])
        validate_df.append(split[2])
    train_df, test_df, validate_df = pd.concat(train_df), pd.concat(test_df), pd.concat(validate_df)
    train_df.to_csv(train, index=False, sep="\t", header=False)
    test_df.to_csv(test, index=False, sep="\t", header=False)
    validate_df.to_csv(validate, index=False, sep="\t", header=False)


if __name__ == "__main__":
    main()
