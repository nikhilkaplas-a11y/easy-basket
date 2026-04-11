# Upgrade EC2 to t3.small (2 GiB) for on-server builds

**t3.micro (1 GiB)** is too tight for `npm run build` (TypeScript) plus the OS; **t3.small (2 GiB)** fits compiling on the instance and matches the default `npm run build` heap (1536 MB).

## Change instance type (AWS Console)

1. In **EC2 → Instances**, select the instance.
2. **Instance state → Stop instance** (wait until **stopped**).
3. **Actions → Instance settings → Change instance type**.
4. Choose **t3.small** (2 vCPU, 2 GiB memory).
5. **Instance state → Start instance**.

Elastic IP (if attached) stays the same after stop/start.

## Change instance type (AWS CLI)

```bash
INSTANCE_ID=i-xxxxxxxx
aws ec2 stop-instances --instance-ids "$INSTANCE_ID"
aws ec2 wait instance-stopped --instance-ids "$INSTANCE_ID"
aws ec2 modify-instance-attribute --instance-id "$INSTANCE_ID" --instance-type "{\"Value\": \"t3.small\"}"
aws ec2 start-instances --instance-ids "$INSTANCE_ID"
```

## After upgrade

- Run **`npm run build`** in `backend/` as usual (no need for `build:micro`).
- If you still use **t3.micro**, use **`npm run build:micro`** instead.

## Cost note

t3.small costs more per hour than t3.micro; see current [EC2 pricing](https://aws.amazon.com/ec2/pricing/on-demand/) for your region.
