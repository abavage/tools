# Validating Admission Policy — PodDisruptionBudget

This directory contains Kubernetes manifests that use a [ValidatingAdmissionPolicy](https://kubernetes.io/docs/reference/access-authn-authz/validating-admission-policy/) (GA in Kubernetes v1.30) to enforce safe `PodDisruptionBudget` (PDB) configurations across a cluster.

## Problem

Misconfigured PDBs can silently block node drains and cluster maintenance:

- `maxUnavailable: 0` — no pods may be disrupted, which prevents voluntary evictions entirely.
- `minAvailable` set to the full replica count (or `100%`) — same effect; all pods must remain available, so none can be evicted.

## Files

| File | Kind | Purpose |
|---|---|---|
| `validating-admission.yaml` | `ValidatingAdmissionPolicy` | Defines the CEL-based validation rules that reject unsafe PDB configurations on `CREATE` and `UPDATE`. |
| `validatingadmissionpolicybinding.yaml` | `ValidatingAdmissionPolicyBinding` | Binds the policy to all namespaces with the `Deny` action so violations are rejected at admission time. |
| `pdb.yaml` | `PodDisruptionBudget` | Example PDB in the `test` namespace that intentionally sets `maxUnavailable: 0`, which will be **rejected** by the policy above. |

## Validation Rules

The policy (`validate-pdb-configuration`) enforces two rules:

1. **`maxUnavailable` must not be `0` or `"0%"`**
   - Reason: A value of `0` completely blocks node drains and voluntary disruptions.
   - Allowed: field absent, any positive integer, or any percentage other than `"0%"`.

2. **`minAvailable` must not be positive or `"100%"`**
   - Reason: Setting `minAvailable` to a non-zero value (or `"100%"`) prevents any voluntary disruptions.
   - Allowed: field absent, `0`, or any percentage other than `"100%"`.

## Usage

Apply the policy and binding to your cluster:

```bash
kubectl apply -f validating-admission.yaml
kubectl apply -f validatingadmissionpolicybinding.yaml
```

Test that the policy rejects the example bad PDB:

```bash
kubectl apply -f pdb.yaml
# Expected: admission webhook denied the request — maxUnavailable cannot be 0 or 0%
```

## Requirements

- Kubernetes **v1.28+** (ValidatingAdmissionPolicy is stable from v1.30; available as beta from v1.28).
- CEL expression evaluation must be enabled (on by default in v1.28+).
