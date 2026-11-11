# Sample handler: conversion that only rewrites apiVersion (fields are kept as they are).
def convert(objects, desired):
    out = []
    for o in objects:
        o = dict(o)
        o["apiVersion"] = desired
        out.append(o)
    return out
